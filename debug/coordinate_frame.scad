include <../utils/vector_operations.scad>

// __private__ single arrow
module __spp__coordinate_frame_arrow(clr="white", H=10, fn=$fn)
{
    // arrow body height
    _h = 0.8*H;
    // arrow body diameter
    _d = 0.1*H;
    color(clr)
    {   
        // arrow body
        %cylinder(h=_h,d=_d,$fn=fn);
        // arrow point
        %translate([0,0,_h])
            cylinder(h=H-_h,d1=H-_h,d2=0,$fn=fn);
    }
}

// Coordinate frame consiting of three XYZ-axes
// '-> NOTE: all components have background modifiers so they are not part of resulting model
// '-> optional argument 'height' is the length of the particular axis
// '-> optional argument 'txt' is optional text to label coordinate frame
// '-> optional argument 'txt_off' is a 3D vector denoting text offset
// '-> optional argument 'txt_rot' is a 3D vector denoting text orientation 
module coordinate_frame(height=10, txt="", txt_off=[0,0,0], txt_rot=[90, 0, -45], fn=$fn)
{
    // x-axis in RED
    rotate([0,90,0])
        __spp__coordinate_frame_arrow(clr="red", H=height, fn=fn);

    // y-axis in GREEN
    rotate([-90,0,0])
        __spp__coordinate_frame_arrow(clr="green", H=height, fn=fn);
    
    // z-axis in BLUE
    __spp__coordinate_frame_arrow(clr="blue", H=height, fn=fn);
    
    // origin in blackish
    _blackish = [0.2,0.2,0.2];
    color(_blackish)
        %sphere(d=0.1*height,$fn=fn);
    
    // text rotation
    assert(is_vector_3D(txt_rot), "[coordinate-frame] the 'txt_rot' is not 3D vector!");
    _tf_rot = txt_rot;

    // text offset
    assert(is_vector_3D(txt_off), "[coordinate-frame] the 'txt_off' is not 3D vector!");
    _tf_off = txt_off;

    // adding text denoting the coordinate frame in blackish
    color(_blackish)
        // rotate it outside of the frame cross
        translate(_tf_off)
            rotate(_tf_rot)
                %linear_extrude(0.1*height)
                    text(txt,valign="center", halign="center",size=0.3*height);

    // adding all other children
    children();
}