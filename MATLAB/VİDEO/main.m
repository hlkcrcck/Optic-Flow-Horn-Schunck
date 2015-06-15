clear all;
close all;
clc;

ite = 10;  %iterasyon sayisi
alpha = 50; %yumuþaklik katsayisi
arkaplan = 0;   %arkaplan ayrýþtýrma yapmak için deðeri 1 girebilirsiniz(optik akýþ için 0)
arkaplan_sinir = 0.05;  %arkaplan ayrýþtýrmada kullanýlacak eþik deðeri
gauss_size = 5; %gauss filtremizin kernel boyutu lütfen tek sayý giriniz


Object=VideoReader('viptraffic.avi');  %iþlem yapacaðýmýz video nun okunmasý

%videonun özelliklerinin alýnmasý
oldvidHeight=Object.Height;
oldvidWidth=Object.Width;
framerate=Object.FrameRate;
NumFrames = Object.NumberOfFrames;

%çözünürlük düþtükten sonraki boyutlar
vidHeight=ceil(oldvidHeight*360/oldvidWidth);
vidWidth=ceil(oldvidWidth*360/oldvidWidth);

kernel_1=[1/12 1/6 1/12;1/6 0 1/6;1/12 1/6 1/12];
vid=zeros(vidHeight,vidWidth,NumFrames);
uvid=zeros(vidHeight,vidWidth,NumFrames-1);
vvid=zeros(vidHeight,vidWidth,NumFrames-1);

%gauss filtremizin oluþturulmasý
H = fspecial('gaussian',gauss_size);

%arkaplan ayrýþtýrma iþlemi
if arkaplan==1
vidrgb=zeros(vidHeight,vidWidth,3,NumFrames);
opvid=zeros(vidHeight,vidWidth,NumFrames-1);

%gri düzey gauss filtrelenmiþ düþük çözünürlüklü videonun elde ediliþi
for k=1:NumFrames
    resized=imresize(rgb2gray(read(Object,k)),360/oldvidWidth);
    vid(:,:,k)=imfilter(im2double(resized),H,'replicate');
end
%rgb gauss filtrelenmiþ düþük çözünürlüklü videonun elde ediliþi
for k=1:NumFrames
    resized=imresize(read(Object,k),360/oldvidWidth);
    vidrgb(:,:,:,k)=imfilter(im2double(resized),H,'replicate');
end
clear Object;clear resized;

%bu kýsým raporda anlatýlmýþtý
for k=2:NumFrames
    [Dx,Dy,Dt] = turev(vid(:,:,k-1),vid(:,:,k));
    for i=1:ite
      uAvg=conv2(uvid(:,:,k-1),kernel_1,'same');
      vAvg=conv2(vvid(:,:,k-1),kernel_1,'same');
      uvid(:,:,k-1)= uAvg - ( Dx.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
      vvid(:,:,k-1)= vAvg - ( Dy.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
    end
    %optik akýþýn þiddetini bulalým
    opvid(:,:,k-1)=sqrt(uvid(:,:,k-1).^2+vvid(:,:,k-1).^2);
end
clear vid;clear uvid;clear vvid;

%videonun renklere ayrýþtýrýlmasý
vidr=vidrgb(:,:,1,:);
vidg=vidrgb(:,:,2,:);
vidb=vidrgb(:,:,3,:);

%eþik deðerin altýnda kalan hareketlerin sýfýrlanmaso
vidr(opvid*255*255<arkaplan_sinir)=0;
vidg(opvid*255*255<arkaplan_sinir)=0;
vidb(opvid*255*255<arkaplan_sinir)=0;

%arkaplandan ayrýþtýrýlmýþ görüntünün birleþimi
vidrgb(:,:,1,:)=vidr;
vidrgb(:,:,2,:)=vidg;
vidrgb(:,:,3,:)=vidb;
clear vidr;clear vidg;clear vidb;

%dosyaya yazmak
writerObj = VideoWriter('ARKAPLANCIKARMA.avi');
writerObj.FrameRate = framerate;
open(writerObj);
writeVideo(writerObj,vidrgb*0.99);
close(writerObj);
end

%hsv renk çemberiyle optik akýþýn gösterimi
if arkaplan==0
    
    %gri düzey gauss filtrelenmiþ düþük çözünürlüklü videonun elde ediliþi
for k=1:NumFrames
    resized=imresize(rgb2gray(read(Object,k)),360/oldvidWidth);
    vid(:,:,k)=imfilter(im2double(resized),H,'replicate');
end

clear Object;clear resized;
op3vid=zeros(vidHeight,vidWidth,3,NumFrames-1);

for k=2:NumFrames
    [Dx,Dy,Dt] = turev(vid(:,:,k-1),vid(:,:,k));
    for i=1:ite
      uAvg=conv2(uvid(:,:,k-1),kernel_1,'same');
      vAvg=conv2(vvid(:,:,k-1),kernel_1,'same');
      uvid(:,:,k-1)= uAvg - ( Dx.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
      vvid(:,:,k-1)= vAvg - ( Dy.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
    end
    %optik akýþýn renk ile kodlanmasý
    op3vid(:,:,:,k-1)=computeColor(uvid(:,:,k-1)*255*255,vvid(:,:,k-1)*255*255);
end
clear vid;clear uvid; clear vvid;
writerObj2 = VideoWriter('OPTÝKAKÝS.avi');
writerObj2.FrameRate = framerate;
open(writerObj2);
writeVideo(writerObj2,op3vid/255);
close(writerObj2);
end

clear all;

