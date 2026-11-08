shader_type spatial;
uniform vec4 stone_color : source_color = vec4(0.40,0.42,0.48,1.0);
uniform float tile_scale = 2.3;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=world_position.xz*tile_scale;
 p.x+=mod(floor(p.y),2.0)*0.5;
 vec2 cell=floor(p);vec2 edge=abs(fract(p)-0.5);
 float grout=smoothstep(0.43,0.49,max(edge.x,edge.y));
 float grain=hash(floor(world_position.xz*110.0));
 ALBEDO=mix(stone_color.rgb*(0.78+hash(cell)*0.35)+(grain-0.5)*0.035,vec3(0.16,0.18,0.23),grout);
 ROUGHNESS=0.9;
}
