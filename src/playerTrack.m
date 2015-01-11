function [PlayInUpCol, PlayInUpRow, PlayInDownCol, PlayInDownRow] = playerTrack( VideofileName, frame, lt, rt, lb, rb)

disp('Begin player track ...');
%read the frame from video
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xyloObj = VideoReader(['video/' VideofileName]);
rows = xyloObj.Height;
cols = xyloObj.Width;
RGB = read(xyloObj);

if(exist('frame','var'))
    numOfFrame = size(frame,2);
else
    numOfFrame = size(RGB,4);
end

PlayInUpCol = zeros(RGB,2);
PlayInUpRow = zeros(RGB,2);
PlayInDownCol = zeros(RGB,2);
PlayInDownRow = zeros(RGB,2);

if(exist('frame','var'))
    for i = 1 : numOfFrame
        [PlayInUpCol(i,:), PlayInUpRow(i,:), PlayInDownCol(i,:), PlayInDownRow(i,:)] = ...
            playerTrackSub(RGB(:,:,:,frame(i)), rows, cols, lt(i,:)', rt(i,:)', lb(i,:)', rb(i,:)');
    end
else
    for i = 1 : numOfFrame
        [PlayInUpCol(i,:), PlayInUpRow(i,:), PlayInDownCol(i,:), PlayInDownRow(i,:)] = ...
            playerTrackSub(RGB(:,:,:,i), rows, cols, lt(i,:)', rt(i,:)', lb(i,:)', rb(i,:)');
    end
end

end

function [PlayInUpCol, PlayInUpRow, PlayInDownCol, PlayInDownRow] = playerTrackSub (RGB, rows, cols, lt, rt, lb, rb)

%spilt court
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=(int16(lb(2,1))-(rows/4)):rows
    for j=1:cols
        frameDownHalf(i-(int16(lb(2,1))-(rows/4))+1,j,:)=RGB(i,j,:);
    end
end
%i=1 to center line 
for i=1:int16(lt(2,1))+(rows/12)
    for j=1:cols
        frameUpHalf(i,j,:)=RGB(i,j,:);
    end
end

%Downframe quntize and count
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HSVDownframe = rgb2hsv(frameDownHalf);
HDownframe = HSVDownframe(:,:,1);
VDownframe = HSVDownframe(:,:,3);
[QframeDownHalfH,~] = quntize(HDownframe,12);
[QframeDownHalfV,~] = quntize(VDownframe,12);
HframeDownMean=sum(sum(double(QframeDownHalfH)))/(rows*cols);
HframeDownVar=var(double(QframeDownHalfH(:)));
VframeDownMean=sum(sum(double(QframeDownHalfV)))/(rows*cols);
VframeDownVar=var(double(QframeDownHalfV(:)));
HframeDownAlpha=(0.5/6+HframeDownVar)/(HframeDownVar);
VframeDownAlpha=(0.5/6+VframeDownVar)/(VframeDownVar);
%for i=1 to height of downHalf
for i=1:rows-(int16(lb(2,1))-(rows/4))+1
    for j=1:cols
        if (abs(double(QframeDownHalfH(i,j))-HframeDownMean) > double(sqrt(HframeDownVar)) || ...
                abs(double(QframeDownHalfV(i,j))-double(VframeDownMean)) > double(sqrt(VframeDownVar)))
            frameDownYesOrNot(i,j,:) = 255;
        else            
            frameDownYesOrNot(i,j,:) = 0;
        end
    end
end

%Upframe quntize and count
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HSVUpframe = rgb2hsv(frameUpHalf);
HUpframe = HSVUpframe(:,:,1);
VUpframe = HSVUpframe(:,:,3);
[QframeUpHalfH,~] = quntize(HUpframe,12);
[QframeUpHalfV,~] = quntize(VUpframe,6);
HframeUpMean=sum(sum(double(QframeUpHalfH)))/(rows*cols);
HframeUpVar=var(double(QframeUpHalfH(:)));
VframeUpMean=sum(sum(double(QframeUpHalfV)))/(rows*cols);
VframeUpVar=var(double(QframeUpHalfV(:)));
Hcourtalpha=(0.5/6+HframeUpVar)/(HframeUpVar);
Vcourtalpha=(0.5/6+VframeUpVar)/(VframeUpVar);
%for i=1 to height of UpHalf
for i=1:int16(lt(2,1))+(rows/12)
     for j=1:cols
         if (abs(double(QframeUpHalfH(i,j))-HframeUpMean) > double(sqrt(HframeUpVar)) || ...
                 abs(double(QframeUpHalfV(i,j))-double(VframeUpMean)) > double(sqrt(VframeUpVar)))
             frameUpYesOrNot(i,j,:)=255;
         else            
             frameUpYesOrNot(i,j,:)=0;
         end
     end
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fDownrows,fDowncols]=size(frameDownYesOrNot);
 for i=1:fDownrows
        for j=1:fDowncols
            %if i between center line to lb
            if(i<int16(lb(2,1))-(rows-fDownrows))
                %if j between lb to rb
                if(j>int16(lb(1,1))+int16(fDowncols/9) && j<int16(rb(1,1))-int16(fDowncols/9))
                    frameDownYesOrNot1(i,j,:)=frameDownYesOrNot(i,j,:);
                else
                    frameDownYesOrNot1(i,j,:)=255;
                end
            else
                frameDownYesOrNot1(i,j,:)=255;
            end
       end
end
Downcount=0;
sumDowni=0;
sumDownj=0;
PlayInDownXY=zeros(1000,2);
for i=1:fDownrows
     for j=1:fDowncols
         if(frameDownYesOrNot1(i,j)==0)
             Downcount=Downcount+1;
             sumDowni=sumDowni+i;
             sumDownj=sumDownj+j;
             PlayInDownXY(Downcount,1)=i;
             PlayInDownXY(Downcount,2)=j;
         end
     end
end
PlayInDownRow=ceil(double(sumDowni/Downcount)+(rows-fDownrows));
PlayInDownCol=ceil(double(sumDownj/Downcount));
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fUprows,fUpcols]=size(frameUpYesOrNot);
 for i=1:fUprows
        for j=1:fUpcols
            %if i between lt to fUprows
            if(i>int16(lt(2,1))-int16(fUprows/5) && i<int16(lt(2,1)))
                %if j between lt to rt
                if(j>int16(lt(1,1))-int16(fUpcols/10) && j<int16(rt(1,1))+int16(fUpcols/10))
                    frameUpYesOrNot1(i,j,:)=frameUpYesOrNot(i,j,:);
                else
                    frameUpYesOrNot1(i,j,:)=255;
                end
            else
                frameUpYesOrNot1(i,j,:)=255;
            end
       end
end
count=0;
sumi=0;
sumj=0;
PlayInUpXY=zeros(1000,2);
for i=1:fUprows
     for j=1:fUpcols
         if(frameUpYesOrNot1(i,j)==0)
             count=count+1;
             sumi=sumi+i;
             sumj=sumj+j;
             PlayInUpXY(count,1)=i;
             PlayInUpXY(count,2)=j;
         end
     end
end
PlayInUpRow=ceil(double(sumi/count));
PlayInUpCol=ceil(double(sumj/count));
disp('Player track done.');

end