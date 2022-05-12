//All intersection functions come from:
//https://iquilezles.org/articles/intersectors/

//Sphere
//Keyword: _LIGHTSHAPE_SPHERE
// Ray-sphere intersection. Returns the distance to the first and second intersection along the ray (or -1 if ray misses)
float2 SphereIntersection(float3 rayOrigin, float3 rayDirection)
{
    float sphereRadius = 1.0f;
    float3 center = float3(0, 0, 0);

    rayOrigin -= center;
    float a = dot(rayDirection, rayDirection);
    float b = 2.0 * dot(rayOrigin, rayDirection);
    float c = dot(rayOrigin, rayOrigin) - (sphereRadius * sphereRadius);
    float d = b * b - 4 * a * c;
    
    if (d < 0)
    {
        return -1;
    }
    else
    {
        d = sqrt(d);
        return float2(-b - d, -b + d) / (2 * a);
    }
}

//Box
//Keyword: _LIGHTSHAPE_BOX
float2 BoxIntersection(float3 rayOrigin, float3 rayDirection)
{
    float3 boxSize = float3(0.5, 0.5, 0.5);
    float3 outNormal = 0;

    float3 m = 1.0 / rayDirection; // can precompute if traversing a set of aligned boxes
    float3 n = m * rayOrigin; // can precompute if traversing a set of aligned boxes
    float3 k = abs(m) * boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);

    if (tN > tF || tF < 0.0) return -1; // no intersection
    outNormal = -sign(rayDirection) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);

    return float2(tN, tF);
}

//Capsule
//Keyword: _LIGHTSHAPE_CAPSULE
//Use cuboid mesh + Sphere intersect is a better choose
// capsule defined by extremes pa and pb, and radius ra
// Note that only ONE of the two spherical caps is checked for intersections,
// which is a nice optimization
float CapIntersect(float3 ro, float3 rd)
{
    float3 pa = float3(0.0, -0.3, 0);
    float3 pb = float3(0.0, 0.3, 0);
    float ra = 0.2;

    float3 ba = pb - pa;
    float3 oa = ro - pa;
    float baba = dot(ba, ba);
    float bard = dot(ba, rd);
    float baoa = dot(ba, oa);
    float rdoa = dot(rd, oa);
    float oaoa = dot(oa, oa);
    float a = baba - bard * bard;
    float b = baba * rdoa - baoa * bard;
    float c = baba * oaoa - baoa * baoa - ra * ra * baba;
    float h = b * b - a * c;
    if (h >= 0.0)
    {
        float t = (-b - sqrt(h)) / a;
        float y = baoa + t * bard;
        // body
        if (y > 0.0 && y < baba) return t;
        // caps
        float3 oc = (y <= 0.0) ? oa : ro - pb;
        b = dot(rd, oc);
        c = dot(oc, oc) - ra * ra;
        h = b * b - c;
        if (h > 0.0) return -b - sqrt(h);
    }
    return -1.0;
}

//RounedCone
//Keyword: _LIGHTSHAPE_ROUNDEDCONE
float4 RoundedConeIntersect(float3 ro, float3 rd)
{
    float3 pa = float3(0, -0.3, -0);
    float3 pb = float3(0, 0.35, 0);
    float ra = 0.3;
    float rb = 0.1;

    float3 ba = pb - pa;
    float3 oa = ro - pa;
    float3 ob = ro - pb;
    float rr = ra - rb;
    float m0 = dot(ba, ba);
    float m1 = dot(ba, oa);
    float m2 = dot(ba, rd);
    float m3 = dot(rd, oa);
    float m5 = dot(oa, oa);
    float m6 = dot(ob, rd);
    float m7 = dot(ob, ob);

    // body
    float d2 = m0 - rr * rr;
    float k2 = d2 - m2 * m2;
    float k1 = d2 * m3 - m1 * m2 + m2 * rr * ra;
    float k0 = d2 * m5 - m1 * m1 + m1 * rr * ra * 2.0 - m0 * ra * ra;
    float h = k1 * k1 - k0 * k2;
    if (h < 0.0) return float4(-1.0, -1, -1, -1);
    float t = (-sqrt(h) - k1) / k2;
    //if( t<0.0 ) return vec4(-1.0);
    float y = m1 - ra * rr + t * m2;
    if (y > 0.0 && y < d2) return float4(t, normalize(d2 * (oa + t * rd) - ba * y));

    // caps
    float h1 = m3 * m3 - m5 + ra * ra;
    float h2 = m6 * m6 - m7 + rb * rb;
    if (max(h1, h2) < 0.0) return float4(-1.0, -1, -1, -1);
    float4 r = float4(999999, 999999, 999999, 999999);
    if (h1 > 0.0)
    {
        t = -m3 - sqrt(h1);
        r = float4(t, (oa + t * rd) / ra);
    }
    if (h2 > 0.0)
    {
        t = -m6 - sqrt(h2);
        if (t < r.x)
            r = float4(t, (ob + t * rd) / rb);
    }
    return r;
}

//Ellipsoid
//Keyword: _LIGHTSHAPE_ELLIPSOID
// ellipsoid centered at the origin with radii ra
float2 EllipsoidIntersect(float3 ro, float3 rd)
{
    //float3 ra = float3(0.8,0.5,0.8);
    float3 ra = float3(1, 0.55, 1);

    float3 ocn = ro / ra;
    float3 rdn = rd / ra;
    float a = dot(rdn, rdn);
    float b = dot(ocn, rdn);
    float c = dot(ocn, ocn);
    float h = b * b - a * (c - 1.0);
    if (h < 0.0) return float2(-1.0, -1.0); //no intersection
    h = sqrt(h);
    return float2(-b - h, -b + h) / a;
}

//Sphere4
//Keyword: _LIGHTSHAPE_SPHERE4
float Sph4Intersect(float3 ro, float3 rd)
{
    float ra = 0.3f;

    float r2 = ra * ra;
    float3 d2 = rd * rd;
    float3 d3 = d2 * rd;
    float3 o2 = ro * ro;
    float3 o3 = o2 * ro;
    float ka = 1.0 / dot(d2, d2);
    float k3 = ka * dot(ro, d3);
    float k2 = ka * dot(o2, d2);
    float k1 = ka * dot(o3, rd);
    float k0 = ka * (dot(o2, o2) - r2 * r2);
    float c2 = k2 - k3 * k3;
    float c1 = k1 + 2.0 * k3 * k3 * k3 - 3.0 * k3 * k2;
    float c0 = k0 - 3.0 * k3 * k3 * k3 * k3 + 6.0 * k3 * k3 * k2 - 4.0 * k3 * k1;
    float p = c2 * c2 + c0 / 3.0;
    float q = c2 * c2 * c2 - c2 * c0 + c1 * c1;
    float h = q * q - p * p * p;
    if (h < 0.0) return -1.0; //no intersection
    float sh = sqrt(h);
    float s = sign(q + sh) * pow(abs(q + sh), 1.0 / 3.0); // cuberoot
    float t = sign(q - sh) * pow(abs(q - sh), 1.0 / 3.0); // cuberoot
    float2 w = float2(s + t, s - t);
    float2 v = float2(w.x + c2 * 4.0, w.y * sqrt(3.0)) * 0.5;
    float r = length(v);
    return -abs(v.y) / sqrt(r + v.x) - c1 / r - k3;
}

float4 GetIntersection(float3 rayOrigin, float3 rayDirection)
{
    float4 result = 0;
    #ifdef _LIGHTSHAPE_SPHERE
    result.xy = SphereIntersection(rayOrigin, rayDirection);
    #elif _LIGHTSHAPE_BOX
    result.xy = BoxIntersection(rayOrigin, rayDirection);
    #elif _LIGHTSHAPE_CAPSULE
    //result.xy = CapIntersect(rayOrigin, rayDirection);
    #elif _LIGHTSHAPE_ROUNDEDCONE
    //result = RoundedConeIntersect(rayOrigin, rayDirection);
    #elif _LIGHTSHAPE_ELLIPSOID
    result.xy += EllipsoidIntersect(rayOrigin, rayDirection);
    #elif _LIGHTSHAPE_SPHERE4
    //result.xy += Sph4Intersect(rayOrigin, rayDirection);
    #endif

    return result;
}
