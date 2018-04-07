half3 CameraRight() {
	return UNITY_MATRIX_V._m00_m01_m02;
}

half3 CameraUp() {
	return UNITY_MATRIX_V._m10_m11_m12;
}

half3 CameraForward() {
	return -UNITY_MATRIX_V._m20_m21_m22;
}

void CamRay(float3 wp, inout float3 ro, inout float3 rd) {
	ro = _WorldSpaceCameraPos; // ray origin is camera position
	rd = normalize(wp - _WorldSpaceCameraPos); // compute ray direction
}

float3 PivotPosition() {
	return unity_ObjectToWorld._m30_m31_m32;
}

half3 ObjectScale() {
	return half3(
		length(unity_ObjectToWorld._m00_m10_m20),
		length(unity_ObjectToWorld._m01_m11_m21),
		length(unity_ObjectToWorld._m02_m12_m22)
	);
}

float GetMipMapLevel(half2 _uv)
{
	half2  dx = ddx(_uv);
	half2  dy = ddy(_uv);
	float delta_max_sqr = max(dot(dx, dx), dot(dy, dy));
	float mml = 0.5 * log2(delta_max_sqr);
	return max(0, mml);
}
