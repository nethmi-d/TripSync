import { createRemoteJWKSet, jwtVerify } from "jose";

interface Env {
  FIREBASE_PROJECT_ID: string;
  CLOUDINARY_CLOUD_NAME: string;
  CLOUDINARY_API_KEY: string;
  CLOUDINARY_API_SECRET: string;
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

      const uid = await authenticate(request, env);

      if (url.pathname === "/v1/profile-photo" && request.method === "POST") {
        return uploadProfilePhoto(request, env, uid);
      }

      if (url.pathname === "/v1/profile-photo" && request.method === "DELETE") {
        return deleteProfilePhoto(env, uid);
      }

      const tripCoverMatch = url.pathname.match(
        /^\/v1\/trips\/([^/]+)\/cover-photo$/,
      );
      if (tripCoverMatch && request.method === "POST") {
        return uploadTripCoverPhoto(request, env, uid, tripCoverMatch[1]);
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

async function authenticate(request: Request, env: Env): Promise<string> {
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
  return payload.sub;
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
  error?: { message?: string };
}
