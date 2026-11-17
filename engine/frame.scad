// Frames shared by the transforms and the face helpers

// frame (4x4 matrix) with the origin 'o' and the z-axis 'nz' (unit vector): y is the projection of
// +z (up) to the plane, +y when the plane is horizontal; x = y × z, so text on the plane reads from
// the side 'nz' points to
function __spp_frame(o, nz) =
    let(
        up = [0, 0, 1],
        yp = up - (up*nz)*nz,
        y = norm(yp) > 1e-9 ? yp / norm(yp) : [0, 1, 0],
        x = cross(y, nz)
    )
    [[x[0], y[0], nz[0], o[0]], [x[1], y[1], nz[1], o[1]], [x[2], y[2], nz[2], o[2]], [0, 0, 0, 1]];

// inverse of a frame (rotation transposed)
function __spp_frame_inverse(M) =
    let(
        R = [[M[0][0], M[1][0], M[2][0]], [M[0][1], M[1][1], M[2][1]], [M[0][2], M[1][2], M[2][2]]],
        o = [M[0][3], M[1][3], M[2][3]],
        t = -(R * o)
    )
    [[R[0][0], R[0][1], R[0][2], t[0]], [R[1][0], R[1][1], R[1][2], t[1]], [R[2][0], R[2][1], R[2][2], t[2]], [0, 0, 0, 1]];

// unit vector of a face letter: "x" -> [-1, 0, 0], "X" -> [1, 0, 0], ...
function __spp_letter_vector(c) =
    c == "x" ? [-1, 0, 0] : c == "X" ? [1, 0, 0] :
    c == "y" ? [0, -1, 0] : c == "Y" ? [0, 1, 0] :
    c == "z" ? [0, 0, -1] : c == "Z" ? [0, 0, 1] : undef;
