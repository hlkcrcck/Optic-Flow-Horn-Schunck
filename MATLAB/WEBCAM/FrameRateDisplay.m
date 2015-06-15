function [res]= FrameRateDisplay(obj, event,vid)
persistent IM;
persistent handlesRaw;
persistent handlesPlot;
persistent Old;
persistent height;
persistent width;

trigger(vid);
IM=getdata(vid,1,'uint8');
H = fspecial('gaussian',10);
ite = 5;
alpha = 1;
kernel_1=[1/12 1/6 1/12;1/6 0 1/6;1/12 1/6 1/12];
if isempty(handlesRaw)
   [height,width]=size(IM);
   % if first execution, we create the figure objects
   subplot(2,1,1);
   handlesRaw=imshow(IM);
   % Plot first value
   subplot(2,1,2);
   handlesPlot=imshow(IM);
   Old=imfilter(im2double(IM),H,'replicate');
else
   IM=imfilter(im2double(IM),H,'replicate');
   [Dx,Dy,Dt] = turev(Old,IM);
   uvid=zeros(height,width);
   vvid=zeros(height,width);
   for i=1:ite
      uAvg=conv2(uvid,kernel_1,'same');
      vAvg=conv2(vvid,kernel_1,'same');
      uvid= uAvg - ( Dx.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
      vvid= vAvg - ( Dy.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
    end
   % We only update what is needed
   set(handlesRaw,'CData',IM*255);
   set(handlesPlot,'CData',uvid*255*255);
   Old=IM;
   res=IM;
end
