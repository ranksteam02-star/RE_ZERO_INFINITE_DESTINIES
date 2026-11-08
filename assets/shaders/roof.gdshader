shader_type spatial;
void fragment(){
 vec2 p=UV*vec2(12.0,16.0);p.x+=mod(floor(p.y),2.0)*0.5;
 vec2 f=fract(p);
 float seam=smoothstep(0.90,1.0,f.y)+smoothstep(0.94,1.0,f.x);
 float h=fract(sin(dot(floor(p),vec2(127.1,311.7)))*43758.5453);
 ALBEDO=mix(vec3(0.21,0.24,0.34)*(0.85+h*0.25),vec3(0.11,0.13,0.20),min(seam,1.0)*0.6);
 ROUGHNESS=0.85;
}
