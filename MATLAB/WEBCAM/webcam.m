function webcam()

NumberFrameDisplayPerSecond=20;
 
hFigure=figure(1);
 
try
   % For windows
   vid = videoinput('winvideo', 1,'YUY2_320x180');
catch
   try
      % For mac.
      vid = videoinput('macvideo', 1);
   catch
      errordlg('No webcam available');
   end
end
set(vid,'FramesPerTrigger',1);
set(vid,'TriggerRepeat',Inf);
set(vid,'ReturnedColorSpace','grayscale');
triggerconfig(vid, 'Manual');

H = fspecial('gaussian',5);
start(vid);
trigger(vid);
IM=getdata(vid,1,'uint8');
[height,width]=size(IM);
   subplot(2,1,1);
   handlesRaw=imshow(IM);
   subplot(2,1,2);
   handlesPlot=imshow(IM);
   Old=imfilter(im2double(IM(:,:,1)),H,'replicate');
   
ite = 10;
alpha = 10;
kernel_1=[1/12 1/6 1/12;1/6 0 1/6;1/12 1/6 1/12];
while 1==1
trigger(vid);
IM=getdata(vid,1,'uint8');

   IM=imfilter(im2double(IM(:,:,1)),H,'replicate');
   [Dx,Dy,Dt] = turev(Old,IM);
   uvid=zeros(height,width);
   vvid=zeros(height,width);
   for i=1:ite
      uAvg=conv2(uvid,kernel_1,'same');
      vAvg=conv2(vvid,kernel_1,'same');
      uvid= uAvg - ( Dx.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
      vvid= vAvg - ( Dy.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
   end
   set(handlesRaw,'CData',IM*255);
   opflow=computeColor(uvid*255*255,vvid*255*255);
   set(handlesPlot,'CData',opflow);
   Old=IM;
   pause(1/NumberFrameDisplayPerSecond);
end

