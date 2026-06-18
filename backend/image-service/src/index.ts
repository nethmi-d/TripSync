import { createRemoteJWKSet, jwtVerify } from "jose";

interface Env {
  FIREBASE_PROJECT_ID: string;
  CLOUDINARY_CLOUD_NAME: string;
  CLOUDINARY_API_KEY: string;
  CLOUDINARY_API_SECRET: string;
  GOOGLE_MAPS_API_KEY: string;
}

const firebaseKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const url = new URL(request.url);

      if (request.method === "OPTIONS") {
        return cors(new Response(null, { status: 204 }));
      }

      if (request.method === "GET" && url.pathname === "/health") {
        return json({ status: "ok" });
      }

      const auth = await authenticate(request, env);

      if (url.pathname === "/v1/profile-photo" && request.method === "POST") {
        return uploadProfilePhoto(request, env, auth.uid);
      }

      if (url.pathname === "/v1/profile-photo" && request.method === "DELETE") {
        return deleteProfilePhoto(env, auth.uid);
      }

      const tripCoverMatch = url.pathname.match(
        /^\/v1\/trips\/([^/]+)\/cover-photo$/,
      );
      if (tripCoverMatch && request.method === "POST") {
        return uploadTripCoverPhoto(request, env, auth.uid, tripCoverMatch[1]);
      }

      const tripGalleryMatch = url.pathname.match(
        /^\/v1\/trips\/([^/]+)\/gallery-photos$/,
      );
      if (tripGalleryMatch) {
        const tripId = tripGalleryMatch[1];
        const access = await getTripAccess(env, auth, tripId);
        if (request.method === "GET") {
          return listTripGalleryPhotos(env, tripId, access);
        }
        if (request.method === "POST") {
          return uploadTripGalleryPhoto(request, env, tripId, access);
        }
        if (request.method === "DELETE") {
          return deleteTripGalleryPhoto(request, env, tripId, access);
        }
      }

      const tripPlacesMatch = url.pathname.match(
        /^\/v1\/trips\/([^/]+)\/places$/,
      );
      if (tripPlacesMatch) {
        const tripId = tripPlacesMatch[1];
        const access = await getTripAccess(env, auth, tripId);
        if (request.method === "GET") {
          return listTripPlaces(env, tripId, access);
        }
        if (request.method === "POST") {
          return uploadTripPlace(request, env, tripId, access);
        }
        if (request.method === "DELETE") {
          return deleteTripPlace(request, env, tripId, access);
        }
      }

      const tripPlacePreviewMatch = url.pathname.match(
        /^\/v1\/trips\/([^/]+)\/places\/preview$/,
      );
      if (tripPlacePreviewMatch && request.method === "POST") {
        const tripId = tripPlacePreviewMatch[1];
        await getTripAccess(env, auth, tripId);
        return previewGooglePlace(request, env);
      }

      const tripPlacePhotoMatch = url.pathname.match(
        /^\/v1\/trips\/([^/]+)\/places\/photo$/,
      );
      if (tripPlacePhotoMatch && request.method === "GET") {
        const tripId = tripPlacePhotoMatch[1];
        await getTripAccess(env, auth, tripId);
        return serveGooglePlacePhoto(url, env);
      }

      return json({ message: "Not found." }, 404);
    } catch (error) {
      const message =
        error instanceof ServiceError ? error.message : "Internal server error.";
      const status = error instanceof ServiceError ? error.status : 500;
      return json({ message }, status);
    }
  },
};

interface AuthContext {
  uid: string;
  token: string;
}

interface TripAccess {
  uid: string;
  isAdmin: boolean;
}

async function authenticate(request: Request, env: Env): Promise<AuthContext> {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    throw new ServiceError(401, "Authentication is required.");
  }

  const token = authorization.slice("Bearer ".length);
  let payload;
  try {
    ({ payload } = await jwtVerify(token, firebaseKeys, {
      audience: env.FIREBASE_PROJECT_ID,
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
    }));
  } catch {
    throw new ServiceError(401, "Invalid or expired Firebase authentication token.");
  }

  if (!payload.sub) {
    throw new ServiceError(401, "Invalid authentication token.");
  }
  return { uid: payload.sub, token };
}

async function getTripAccess(
  env: Env,
  auth: AuthContext,
  tripId: string,
): Promise<TripAccess> {
  if (!/^[A-Za-z0-9_-]+$/.test(tripId)) {
    throw new ServiceError(400, "Invalid trip ID.");
  }
  const endpoint =
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}` +
    `/databases/(default)/documents/trips/${encodeURIComponent(tripId)}`;
  const response = await fetch(endpoint, {
    headers: { Authorization: `Bearer ${auth.token}` },
  });
  if (response.status === 403) {
    throw new ServiceError(403, "You do not have access to this trip.");
  }
  if (!response.ok) {
    throw new ServiceError(404, "Trip not found.");
  }
  const document = (await response.json()) as FirestoreDocument;
  const createdBy = document.fields?.createdBy?.stringValue;
  const adminIds = firestoreStringArray(document.fields?.adminIds);
  const memberIds = firestoreStringArray(document.fields?.memberIds);
  const isAdmin = createdBy === auth.uid || adminIds.includes(auth.uid);
  if (!isAdmin && !memberIds.includes(auth.uid)) {
    throw new ServiceError(403, "Only trip members can access gallery photos.");
  }
  return { uid: auth.uid, isAdmin };
}

function firestoreStringArray(field?: FirestoreValue): string[] {
  return (field?.arrayValue?.values ?? [])
    .map((value) => value.stringValue)
    .filter((value): value is string => typeof value === "string");
}

async function uploadProfilePhoto(
  request: Request,
  env: Env,
  uid: string,
): Promise<Response> {
  const form = await request.formData();
  const entry = form.get("file");
  if (entry == null || typeof entry === "string") {
    throw new ServiceError(400, "A profile photo is required.");
  }
  const file = entry as File;
  if (!file.type.startsWith("image/")) {
    throw new ServiceError(400, "Only image files are allowed.");
  }
  if (file.size > 2 * 1024 * 1024) {
    throw new ServiceError(400, "Choose a profile photo smaller than 2 MB.");
  }

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const publicId = `tripsync/users/${uid}/profile/avatar`;
  const parameters = {
    invalidate: "true",
    overwrite: "true",
    public_id: publicId,
    timestamp,
  };
  const signature = await cloudinarySignature(parameters, env.CLOUDINARY_API_SECRET);

  const upload = new FormData();
  upload.set("file", file);
  upload.set("api_key", env.CLOUDINARY_API_KEY);
  upload.set("signature", signature);
  Object.entries(parameters).forEach(([key, value]) => upload.set(key, value));

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/image/upload`,
    { method: "POST", body: upload },
  );
  const body = (await response.json()) as CloudinaryResponse;

  if (!response.ok || !body.secure_url || !body.public_id) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not upload the profile photo.",
    );
  }

  return json({ secure_url: body.secure_url, public_id: body.public_id });
}

async function deleteProfilePhoto(env: Env, uid: string): Promise<Response> {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const parameters = {
    invalidate: "true",
    public_id: `tripsync/users/${uid}/profile/avatar`,
    timestamp,
  };
  const signature = await cloudinarySignature(parameters, env.CLOUDINARY_API_SECRET);

  const form = new FormData();
  form.set("api_key", env.CLOUDINARY_API_KEY);
  form.set("signature", signature);
  Object.entries(parameters).forEach(([key, value]) => form.set(key, value));

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/image/destroy`,
    { method: "POST", body: form },
  );
  const body = (await response.json()) as CloudinaryResponse;

  if (!response.ok) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not delete the profile photo.",
    );
  }
  return json({ deleted: true });
}

async function uploadTripCoverPhoto(
  request: Request,
  env: Env,
  uid: string,
  tripId: string,
): Promise<Response> {
  if (!/^[A-Za-z0-9_-]+$/.test(tripId)) {
    throw new ServiceError(400, "Invalid trip ID.");
  }

  const form = await request.formData();
  const entry = form.get("file");
  if (entry == null || typeof entry === "string") {
    throw new ServiceError(400, "A trip cover image is required.");
  }
  const file = entry as File;
  if (!file.type.startsWith("image/")) {
    throw new ServiceError(400, "Only image files are allowed.");
  }
  if (file.size > 5 * 1024 * 1024) {
    throw new ServiceError(400, "Choose a cover image smaller than 5 MB.");
  }

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const publicId = `tripsync/trips/${tripId}/cover`;
  const parameters = {
    context: `uploaded_by=${uid}`,
    invalidate: "true",
    overwrite: "true",
    public_id: publicId,
    timestamp,
  };
  const signature = await cloudinarySignature(
    parameters,
    env.CLOUDINARY_API_SECRET,
  );

  const upload = new FormData();
  upload.set("file", file);
  upload.set("api_key", env.CLOUDINARY_API_KEY);
  upload.set("signature", signature);
  Object.entries(parameters).forEach(([key, value]) => upload.set(key, value));

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/image/upload`,
    { method: "POST", body: upload },
  );
  const body = (await response.json()) as CloudinaryResponse;

  if (!response.ok || !body.secure_url || !body.public_id) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not upload the trip cover image.",
    );
  }

  return json({ secure_url: body.secure_url, public_id: body.public_id });
}

async function listTripGalleryPhotos(
  env: Env,
  tripId: string,
  access: TripAccess,
): Promise<Response> {
  const prefix = `tripsync/trips/${tripId}/gallery/`;
  const query = new URLSearchParams({
    type: "upload",
    prefix,
    context: "true",
    max_results: "100",
    direction: "desc",
  });
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/resources/image/upload?${query}`,
    { headers: cloudinaryAdminHeaders(env) },
  );
  const body = (await response.json()) as CloudinaryListResponse;
  if (!response.ok || !body.resources) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not load gallery photos.",
    );
  }
  const photos = body.resources.map((resource) => ({
    public_id: resource.public_id,
    secure_url: resource.secure_url,
    uploaded_by:
      resource.context?.custom?.uploaded_by ?? ownerFromPublicId(resource.public_id),
    created_at: resource.created_at,
    filename: resource.filename ?? resource.public_id.split("/").at(-1),
    width: resource.width,
    height: resource.height,
    bytes: resource.bytes,
  }));
  return json({ photos, viewer_uid: access.uid, is_admin: access.isAdmin });
}

async function uploadTripGalleryPhoto(
  request: Request,
  env: Env,
  tripId: string,
  access: TripAccess,
): Promise<Response> {
  const form = await request.formData();
  const entry = form.get("file");
  if (entry == null || typeof entry === "string") {
    throw new ServiceError(400, "A gallery photo is required.");
  }
  const file = entry as File;
  if (!file.type.startsWith("image/")) {
    throw new ServiceError(400, "Only image files are allowed.");
  }
  if (file.size > 10 * 1024 * 1024) {
    throw new ServiceError(400, "Choose a gallery photo smaller than 10 MB.");
  }

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const publicId =
    `tripsync/trips/${tripId}/gallery/${access.uid}/${crypto.randomUUID()}`;
  const parameters = {
    context: `uploaded_by=${access.uid}`,
    public_id: publicId,
    timestamp,
  };
  const signature = await cloudinarySignature(parameters, env.CLOUDINARY_API_SECRET);
  const upload = new FormData();
  upload.set("file", file);
  upload.set("api_key", env.CLOUDINARY_API_KEY);
  upload.set("signature", signature);
  Object.entries(parameters).forEach(([key, value]) => upload.set(key, value));

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/image/upload`,
    { method: "POST", body: upload },
  );
  const body = (await response.json()) as CloudinaryResponse;
  if (!response.ok || !body.secure_url || !body.public_id) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not upload the gallery photo.",
    );
  }
  return json({
    secure_url: body.secure_url,
    public_id: body.public_id,
    uploaded_by: access.uid,
    created_at: body.created_at,
    filename: body.original_filename ?? file.name,
    width: body.width,
    height: body.height,
    bytes: body.bytes,
  });
}

async function deleteTripGalleryPhoto(
  request: Request,
  env: Env,
  tripId: string,
  access: TripAccess,
): Promise<Response> {
  let publicId: string | undefined;
  try {
    const body = (await request.json()) as { public_id?: string };
    publicId = body.public_id;
  } catch {
    throw new ServiceError(400, "A photo ID is required.");
  }
  const requiredPrefix = `tripsync/trips/${tripId}/gallery/`;
  if (!publicId?.startsWith(requiredPrefix)) {
    throw new ServiceError(400, "Invalid gallery photo ID.");
  }
  const ownerId = ownerFromPublicId(publicId);
  if (!access.isAdmin && ownerId !== access.uid) {
    throw new ServiceError(403, "You can only delete photos that you added.");
  }

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const parameters = { invalidate: "true", public_id: publicId, timestamp };
  const signature = await cloudinarySignature(parameters, env.CLOUDINARY_API_SECRET);
  const form = new FormData();
  form.set("api_key", env.CLOUDINARY_API_KEY);
  form.set("signature", signature);
  Object.entries(parameters).forEach(([key, value]) => form.set(key, value));
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/image/destroy`,
    { method: "POST", body: form },
  );
  const body = (await response.json()) as CloudinaryResponse;
  if (!response.ok) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not delete the gallery photo.",
    );
  }
  return json({ deleted: true });
}

function ownerFromPublicId(publicId: string): string {
  const parts = publicId.split("/");
  return parts.length >= 2 ? parts.at(-2) ?? "" : "";
}

function cloudinaryAdminHeaders(env: Env): HeadersInit {
  return {
    Authorization: `Basic ${btoa(`${env.CLOUDINARY_API_KEY}:${env.CLOUDINARY_API_SECRET}`)}`,
  };
}

async function listTripPlaces(
  env: Env,
  tripId: string,
  access: TripAccess,
): Promise<Response> {
  const prefix = `tripsync/trips/${tripId}/places/`;
  const query = new URLSearchParams({
    type: "upload",
    prefix,
    context: "true",
    max_results: "100",
    direction: "desc",
  });
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/resources/image/upload?${query}`,
    { headers: cloudinaryAdminHeaders(env) },
  );
  const body = (await response.json()) as CloudinaryListResponse;
  if (!response.ok || !body.resources) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not load trip places.",
    );
  }
  const places = body.resources.map((resource) => {
    const context = resource.context?.custom ?? {};
    return {
      public_id: resource.public_id,
      secure_url: resource.secure_url,
      uploaded_by: context.uploaded_by ?? ownerFromPublicId(resource.public_id),
      added_by_name: context.added_by_name ?? "Trip member",
      created_at: resource.created_at,
      name: context.place_name ?? "Suggested place",
      location: context.location ?? "",
      note: context.note ?? "",
      maps_url: context.maps_url ?? "",
      place_type: context.place_type === "accommodation" ? "accommodation" : "visit",
      google_place_id: context.google_place_id ?? "",
      google_photo_name: context.google_photo_name ?? "",
      google_attribution: context.google_attribution ?? "",
    };
  });
  return json({ places, viewer_uid: access.uid, is_admin: access.isAdmin });
}

async function uploadTripPlace(
  request: Request,
  env: Env,
  tripId: string,
  access: TripAccess,
): Promise<Response> {
  const input = await readJsonObject(request);
  const mapsUrl = requiredJsonText(input, "maps_url", "Google Maps link", 600);
  const note = optionalJsonText(input, "note", 300);
  const addedByName = optionalJsonText(input, "added_by_name", 80) || "Trip member";
  const requestedPlaceId = optionalJsonText(input, "google_place_id", 200);
  if (!isGoogleMapsUrl(mapsUrl)) {
    throw new ServiceError(400, "Enter a valid Google Maps link.");
  }
  const place = requestedPlaceId
    ? await getGooglePlaceDetails(env, requestedPlaceId)
    : await findGooglePlaceFromMapsUrl(env, mapsUrl);
  const placeType = googlePlaceType(place.primaryType);
  const name = place.displayName?.text ?? "Suggested place";
  const location = place.formattedAddress ?? "";
  const photo = place.photos?.[0];
  const attribution = (photo?.authorAttributions ?? [])
    .map((item) => item.displayName)
    .filter((value): value is string => Boolean(value))
    .join(", ");

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const publicId =
    `tripsync/trips/${tripId}/places/${access.uid}/${crypto.randomUUID()}`;
  const context = [
    `uploaded_by=${escapeCloudinaryContext(access.uid)}`,
    `added_by_name=${escapeCloudinaryContext(addedByName)}`,
    `place_name=${escapeCloudinaryContext(name)}`,
    `location=${escapeCloudinaryContext(location)}`,
    `note=${escapeCloudinaryContext(note)}`,
    `maps_url=${escapeCloudinaryContext(place.googleMapsUri ?? mapsUrl)}`,
    `place_type=${placeType}`,
    `google_place_id=${escapeCloudinaryContext(place.id ?? requestedPlaceId)}`,
    `google_photo_name=${escapeCloudinaryContext(photo?.name ?? "")}`,
    `google_attribution=${escapeCloudinaryContext(attribution)}`,
  ].join("|");
  const parameters = { context, public_id: publicId, timestamp };
  const signature = await cloudinarySignature(parameters, env.CLOUDINARY_API_SECRET);
  const upload = new FormData();
  upload.set(
    "file",
    "data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=",
  );
  upload.set("api_key", env.CLOUDINARY_API_KEY);
  upload.set("signature", signature);
  Object.entries(parameters).forEach(([key, value]) => upload.set(key, value));
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/image/upload`,
    { method: "POST", body: upload },
  );
  const body = (await response.json()) as CloudinaryResponse;
  if (!response.ok || !body.secure_url || !body.public_id) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not save this place.",
    );
  }
  return json({
    public_id: body.public_id,
    secure_url: body.secure_url,
    uploaded_by: access.uid,
    added_by_name: addedByName,
    created_at: body.created_at,
    name,
    location,
    note,
    maps_url: place.googleMapsUri ?? mapsUrl,
    place_type: placeType,
    google_place_id: place.id,
    google_photo_name: photo?.name ?? "",
    google_attribution: attribution,
  });
}

async function previewGooglePlace(request: Request, env: Env): Promise<Response> {
  const input = await readJsonObject(request);
  const mapsUrl = requiredJsonText(input, "maps_url", "Google Maps link", 600);
  if (!isGoogleMapsUrl(mapsUrl)) {
    throw new ServiceError(400, "Enter a valid Google Maps link.");
  }
  const place = await findGooglePlaceFromMapsUrl(env, mapsUrl);
  const photo = place.photos?.[0];
  const attribution = (photo?.authorAttributions ?? [])
    .map((item) => item.displayName)
    .filter((value): value is string => Boolean(value))
    .join(", ");
  return json({
    google_place_id: place.id,
    name: place.displayName?.text ?? "Suggested place",
    location: place.formattedAddress ?? "",
    maps_url: place.googleMapsUri ?? mapsUrl,
    place_type: googlePlaceType(place.primaryType),
    google_photo_name: photo?.name ?? "",
    google_attribution: attribution,
  });
}

async function serveGooglePlacePhoto(url: URL, env: Env): Promise<Response> {
  const photoName = url.searchParams.get("name") ?? "";
  if (!/^places\/[^/]+\/photos\/[^/]+$/.test(photoName)) {
    throw new ServiceError(400, "Invalid Google place photo.");
  }
  const endpoint =
    `https://places.googleapis.com/v1/${photoName}/media` +
    "?maxWidthPx=1200&maxHeightPx=900";
  const response = await fetch(endpoint, {
    headers: { "X-Goog-Api-Key": env.GOOGLE_MAPS_API_KEY },
    redirect: "follow",
  });
  if (!response.ok || !response.body) {
    throw new ServiceError(502, "Google could not load this place photo.");
  }
  return cors(new Response(response.body, {
    status: 200,
    headers: {
      "Content-Type": response.headers.get("Content-Type") ?? "image/jpeg",
      "Cache-Control": "private, max-age=3600",
    },
  }));
}

async function findGooglePlaceFromMapsUrl(
  env: Env,
  mapsUrl: string,
): Promise<GooglePlace> {
  const resolvedUrl = await resolveGoogleMapsUrl(mapsUrl);
  const parsed = new URL(resolvedUrl);
  const placeId = parsed.searchParams.get("query_place_id");
  if (placeId) return getGooglePlaceDetails(env, placeId);

  const placePathMatch = decodeURIComponent(parsed.pathname).match(
    /\/maps\/place\/([^/]+)/,
  );
  const textQuery =
    parsed.searchParams.get("query") ??
    parsed.searchParams.get("q") ??
    placePathMatch?.[1]?.replaceAll("+", " ") ??
    "";
  if (!textQuery.trim()) {
    throw new ServiceError(
      400,
      "This Maps link does not contain enough place information.",
    );
  }
  const requestBody: Record<string, unknown> = { textQuery: textQuery.trim() };
  const coordinateMatch = resolvedUrl.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/);
  if (coordinateMatch) {
    requestBody.locationBias = {
      circle: {
        center: {
          latitude: Number(coordinateMatch[1]),
          longitude: Number(coordinateMatch[2]),
        },
        radius: 1000,
      },
    };
  }
  const response = await fetch(
    "https://places.googleapis.com/v1/places:searchText",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": env.GOOGLE_MAPS_API_KEY,
        "X-Goog-FieldMask": googlePlaceFieldMask("places."),
      },
      body: JSON.stringify(requestBody),
    },
  );
  const body = (await response.json()) as GoogleTextSearchResponse;
  if (!response.ok) {
    throw new ServiceError(
      response.status === 403 ? 403 : 502,
      body.error?.message ?? "Google Places could not read this Maps link.",
    );
  }
  const place = body.places?.[0];
  if (!place) throw new ServiceError(404, "No Google place was found.");
  return place;
}

async function getGooglePlaceDetails(env: Env, placeId: string): Promise<GooglePlace> {
  if (!/^[A-Za-z0-9_-]+$/.test(placeId)) {
    throw new ServiceError(400, "Invalid Google place ID.");
  }
  const response = await fetch(
    `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`,
    {
      headers: {
        "X-Goog-Api-Key": env.GOOGLE_MAPS_API_KEY,
        "X-Goog-FieldMask": googlePlaceFieldMask(),
      },
    },
  );
  const body = (await response.json()) as GooglePlace & {
    error?: { message?: string };
  };
  if (!response.ok) {
    throw new ServiceError(
      response.status === 403 ? 403 : 502,
      body.error?.message ?? "Google Places could not load this place.",
    );
  }
  return body;
}

async function resolveGoogleMapsUrl(value: string): Promise<string> {
  const parsed = new URL(value);
  if (parsed.hostname !== "maps.app.goo.gl" && parsed.hostname !== "goo.gl") {
    return value;
  }
  const response = await fetch(value, {
    redirect: "follow",
    headers: { "User-Agent": "Mozilla/5.0 TripSync/1.0" },
  });
  return response.url || value;
}

function googlePlaceFieldMask(prefix = ""): string {
  return [
    "id",
    "displayName",
    "formattedAddress",
    "primaryType",
    "photos",
    "googleMapsUri",
  ].map((field) => `${prefix}${field}`).join(",");
}

function googlePlaceType(primaryType?: string): "visit" | "accommodation" {
  const accommodationTypes = new Set([
    "bed_and_breakfast",
    "campground",
    "guest_house",
    "hostel",
    "hotel",
    "lodging",
    "motel",
    "resort_hotel",
  ]);
  return primaryType && accommodationTypes.has(primaryType)
    ? "accommodation"
    : "visit";
}

async function deleteTripPlace(
  request: Request,
  env: Env,
  tripId: string,
  access: TripAccess,
): Promise<Response> {
  let publicId: string | undefined;
  try {
    const body = (await request.json()) as { public_id?: string };
    publicId = body.public_id;
  } catch {
    throw new ServiceError(400, "A place ID is required.");
  }
  const requiredPrefix = `tripsync/trips/${tripId}/places/`;
  if (!publicId?.startsWith(requiredPrefix)) {
    throw new ServiceError(400, "Invalid place ID.");
  }
  if (!access.isAdmin && ownerFromPublicId(publicId) !== access.uid) {
    throw new ServiceError(403, "You can only delete places that you added.");
  }
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const parameters = { invalidate: "true", public_id: publicId, timestamp };
  const signature = await cloudinarySignature(parameters, env.CLOUDINARY_API_SECRET);
  const form = new FormData();
  form.set("api_key", env.CLOUDINARY_API_KEY);
  form.set("signature", signature);
  Object.entries(parameters).forEach(([key, value]) => form.set(key, value));
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/image/destroy`,
    { method: "POST", body: form },
  );
  const body = (await response.json()) as CloudinaryResponse;
  if (!response.ok) {
    throw new ServiceError(
      502,
      body.error?.message ?? "Cloudinary could not delete this place.",
    );
  }
  return json({ deleted: true });
}

async function readJsonObject(request: Request): Promise<Record<string, unknown>> {
  try {
    const value = await request.json();
    if (value && typeof value === "object" && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }
  } catch {
    // The error below gives the client a stable message.
  }
  throw new ServiceError(400, "Invalid request data.");
}

function requiredJsonText(
  value: Record<string, unknown>,
  key: string,
  label: string,
  maximumLength: number,
): string {
  const item = value[key];
  if (typeof item !== "string" || item.trim().length === 0) {
    throw new ServiceError(400, `${label} is required.`);
  }
  const cleaned = item.trim();
  if (cleaned.length > maximumLength) {
    throw new ServiceError(400, `${label} is too long.`);
  }
  return cleaned;
}

function optionalJsonText(
  value: Record<string, unknown>,
  key: string,
  maximumLength: number,
): string {
  const item = value[key];
  if (typeof item !== "string") return "";
  return item.trim().slice(0, maximumLength);
}

function isGoogleMapsUrl(value: string): boolean {
  try {
    const url = new URL(value);
    const host = url.hostname.toLowerCase();
    const isGoogleDomain = /(^|\.)google\.[a-z.]+$/.test(host);
    return url.protocol === "https:" && (
      host === "maps.app.goo.gl" ||
      host === "goo.gl" ||
      (isGoogleDomain && (
        host.startsWith("maps.google.") ||
        url.pathname === "/maps" ||
        url.pathname.startsWith("/maps/")
      ))
    );
  } catch {
    return false;
  }
}

function escapeCloudinaryContext(value: string): string {
  return value.replaceAll("\\", "\\\\").replaceAll("|", "\\|").replaceAll("=", "\\=");
}

async function cloudinarySignature(
  parameters: Record<string, string>,
  secret: string,
): Promise<string> {
  const value =
    Object.entries(parameters)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, item]) => `${key}=${item}`)
      .join("&") + secret;
  const digest = await crypto.subtle.digest(
    "SHA-1",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function json(body: unknown, status = 200): Response {
  return cors(Response.json(body, {
    status,
    headers: { "Cache-Control": "no-store" },
  }));
}

function cors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
  headers.set(
    "Access-Control-Allow-Headers",
    "Authorization, Content-Type",
  );
  headers.set("Access-Control-Max-Age", "86400");
  return new Response(response.body, { ...response, headers });
}

class ServiceError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

interface CloudinaryResponse {
  secure_url?: string;
  public_id?: string;
  created_at?: string;
  original_filename?: string;
  width?: number;
  height?: number;
  bytes?: number;
  error?: { message?: string };
}

interface CloudinaryListResponse {
  resources?: Array<{
    public_id: string;
    secure_url: string;
    created_at?: string;
    filename?: string;
    width?: number;
    height?: number;
    bytes?: number;
    context?: { custom?: Record<string, string | undefined> };
  }>;
  error?: { message?: string };
}

interface FirestoreDocument {
  fields?: Record<string, FirestoreValue>;
}

interface FirestoreValue {
  stringValue?: string;
  arrayValue?: { values?: FirestoreValue[] };
}

interface GooglePlace {
  id?: string;
  displayName?: { text?: string };
  formattedAddress?: string;
  primaryType?: string;
  googleMapsUri?: string;
  photos?: Array<{
    name?: string;
    authorAttributions?: Array<{ displayName?: string; uri?: string }>;
  }>;
}

interface GoogleTextSearchResponse {
  places?: GooglePlace[];
  error?: { message?: string };
}
