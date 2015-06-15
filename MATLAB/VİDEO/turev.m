function [Dx, Dy, Dt] = turev(im1,im2)
        Dx = conv2(im1,0.25* [-1 0 1; -2 0 2;-1 0 1],'same');
        Dy = conv2(im1, 0.25*[1 2 1;0 0 0; -1 -2 -1], 'same');
        Dt = conv2(im1, 0.25*[-1 1],'same') + conv2(im2, -0.25*[-1 1],'same');
end
