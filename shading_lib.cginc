half3 GetAmbient(half3 _vector) {
	return ShadeSH9(half4(_vector, 1.0));
}

half3 GetSpecCube(half3 _vector, half _smoothness) {

	half mip = _smoothness * 6.0;
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, _vector, mip);
	return DecodeHDR(rgbm, unity_SpecCube0_HDR);
}

half GetSchlickFresnel(half3 _worldNormal, half3 _worldView, half _factor) {
	half nDotV = dot(_worldNormal, _worldView);
	nDotV = 1.0 - nDotV;
	//nDotV = pow(nDotV, 5.0);
	nDotV *= nDotV; nDotV *= nDotV;
	return _factor + (1.0 - _factor) * nDotV;
}

half GetAttenuation(half3 _vector) {
	return  1.0 / dot(_vector, _vector); // inverse square law
}
