shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color : source_color = vec4(0.36,0.16,0.47,1.0);
void vertex(){VERTEX.z+=sin(VERTEX.x*4.0+TIME*2.6)*(1.0-UV.y)*0.13;}
void fragment(){float trim=step(UV.x,0.07)+step(0.93,UV.x)+step(0.94,UV.y); ALBEDO=mix(cloth_color.rgb,vec3(0.8,0.61,0.3),min(trim,1.0));ROUGHNESS=0.95;}
