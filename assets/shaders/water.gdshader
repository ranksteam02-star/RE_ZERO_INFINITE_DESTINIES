shader_type spatial;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_position.xz;
 float ripple=sin(p.x*4.0+sin(p.y*5.0+TIME)*1.6+TIME*1.8)*sin(p.y*6.0-TIME*2.0);
 float glint=pow(max(ripple,0.0),10.0);
 ALBEDO=mix(vec3(0.035,0.19,0.28),vec3(0.08,0.28,0.35),ripple*0.5+0.5);
 EMISSION=vec3(0.25,0.48,0.55)*glint*0.15;
 ROUGHNESS=0.23; METALLIC=0.35;
 NORMAL=normalize(NORMAL+vec3(ripple*0.12,0.0,cos(p.x*9.0+TIME)*0.1));
}
