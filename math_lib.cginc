float SphereRay(float3 ro, float3 rd, float3 spherePos, half sphereRadius)
{
	float3 oc = ro - spherePos; // vector to ray origin
	float b = dot(oc, rd);	// dot with ray direction
	float c = dot(oc, oc) - sphereRadius * sphereRadius; // square magnitude of vector - square radius
	float h = b * b - c;

	if (h < 0.0)
		return -1.0; // no hit

	h = sqrt(h); // actual magnitude
	return -(b + h);
}

float HitSphere(float3 wp, float3 rayOrigin, float3 rayDirection, float3 spherePos, half sphereRadius, inout half3 normal, inout float3 hitPos) {

	float distanceToHit = SphereRay(rayOrigin, rayDirection, spherePos, sphereRadius);

	hitPos = rayOrigin + rayDirection * distanceToHit;
	normal = normalize(hitPos - spherePos);

	return distanceToHit;
}

half HitFlatPlane(half planeHeight, half pointHeight, half3 direction)
{
    return (planeHeight - pointHeight) / direction.y;
}


fixed SphereSoftShadow(float3 ro, half3 rd, float3 spherePos, half sphereRadius)
{
	const half shadowHardness = 50.0;

	half3 oc = ro - spherePos;
	half b = dot(oc, rd);
	half c = dot(oc, oc) - sphereRadius * sphereRadius;
	half h = b * b - c;

	half mask = step(-0.0001, c);
	half shw = smoothstep(0.0, 1.0, h * shadowHardness / b);

	return (b > 0.0) ? 1.0 : shw;
}

half3 TangentToObjectSpace(half3 _input, half3 nml, half3 tgt, half3 btg) {
	return tgt * _input.x + btg * _input.y + nml * _input.z;
}


float RayDistanceToPoint(float3 rayOrigin, float3 rayDirection, float3 pointPos)
{
	return length(cross(rayDirection, pointPos - rayOrigin));
}

float DepthFromPos(float3 pos) {
	float hitDepth = -mul(UNITY_MATRIX_V, float4(pos, 1.0)).z;
	return (1.0 - hitDepth * _ZBufferParams.w) / (hitDepth * _ZBufferParams.z);
}

#define PI 3.14159265
half2 VectorToLongitudeLatitude(half3 v) {		// world vector to longitude latitude coordinates. singularity at (x=0 && z=0) requires disabling of mips or computing mip level manually
	half2 vo = 0;
	vo.x = atan2(v.x, v.z) / PI;
	vo.y = -v.y;
	vo = vo * 0.5 + 0.5;
	return vo;
}


half3 RotateByQuaternion(half3 v, half4 q) {
	half3 t = cross(q.xyz, v) + v * q.w;
	return v + 2.0 * cross(q.xyz, t);
}

half4 Slerp(half4 start, half4 end, float percent) {
	// Dot product - the cosine of the angle between 2 vectors.
	float d = dot(start, end);
	// Clamp it to be in the range of Acos()
	// This may be unnecessary, but floating point
	// precision can be a fickle mistress.
	d = clamp(d, -1.0, 1.0);
	// Acos(dot) returns the angle between start and end,
	// And multiplying that by percent returns the angle between
	// start and the final result.
	float theta = acos(d) * percent;
			
	half s, c;
	sincos(theta, s, c);

	half4 RelativeVec = normalize(end - start * d); // Orthonormal basis
	return (start * c) + (RelativeVec * s);
}

half2 Rotate2D(half2 _in, half _angle) {
	half s, c;
	sincos(_angle, s, c);
	half2 o;
	//o.x = _in.x * c - _in.y * s;
	//o.y = _in.y * c + _in.x * s;
	float2x2 rot = { c, s, -s, c };
	o = mul(rot, _in);
	return o;
}

float3x3 RotationMatrix(float3 _axis, half _angle) {

	half s, c;
	sincos(_angle, s, c);

	half3 sa = _axis * s;
	half3 ca = _axis * (1.0 - c);

	half3 a = ca.xxx * _axis.xyz;
	half3 b = ca.yyz * _axis.yzz;

	return float3x3(
		a.xyz + half3(c, -sa.z, sa.y),
		half3(a.y, b.x, b.y) + half3(sa.z, c, -sa.x),
		half3(a.z, b.y, b.z) + half3(-sa.y, sa.x, c)
	);
}

// Warning! this is openGL 
float3x3 LookAtRotationMatrix(half3 _direction, half3 _up)
{
	half3 xaxis = cross(_up, _direction);
	half3 yaxis = cross(_direction, xaxis);

	half3 c1, c2, c3;

	c1.x = xaxis.x;
	c1.y = yaxis.x;
	c1.z = _direction.x;

	c2.x = xaxis.y;
	c2.y = yaxis.y;
	c2.z = _direction.y;

	c3.x = xaxis.z;
	c3.y = yaxis.z;
	c3.z = _direction.z;

	return float3x3(
		c1.x, c2.x, c3.x,
		c1.y, c2.y, c3.y,
		c1.z, c2.z, c3.z);
}

half3 Sobel(half2 _uv, half2 _invSamplerSize) {

	const half2 baseOffset[8] = {
		half2(-1.0, -1.0), 
		half2( 0.0, -1.0),
		half2( 1.0, -1.0),
		half2(-1.0,  0.0),
		half2( 1.0,  0.0),
		half2(-1.0,  1.0),
		half2( 0.0,  1.0),
		half2( 1.0,  1.0)
	};

	half v[8];

	half2 scale = _samplerSize.xy * 4.0;

	for (int i = 0; i < 8; i++) {
		half2 coord = _uv;
		coord.xy += baseOffset[i].xy * scale;
		v[i] = tex2D(_GrassTex, coord).x;;
	}

	half x = v[0] + 2.0 * v[3] + v[5] - v[2] - 2.0 * v[4] - v[7];
	half y = v[0] + 2.0 * v[1] + v[2] - v[5] - 2.0 * v[6] - v[7];

	half3 n = half3(x, 1.0, y);
	n.y = sqrt(1.0 - dot(n.xz, n.xz));

	return n;
}
