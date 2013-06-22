%% INITIALIZE
clear; close all; clc

%% TAKE THE PATH OF THE IMAGE AS INPUT AND READ THE IMAGE
a = input('     Enter the path of image\n     ','s');
img = imread(a);
clear a;

%% Convert the image into grayscale, Adjust contrast and make binary
img = rgb2gray(img);
img = imadjust(img);
a = ~im2bw(img,0.8);old = a;

%% Apply connected component on inverse of binary image and the location of all
% letters as well as noise
CC = bwconncomp(a);
m1 = CC.NumObjects;
rn = CC.ImageSize(1);
enough = CC.PixelIdxList;
boxmat = zeros(m1,5);
for i = 1:m1
    temp = enough{1,i};
    temp1 = mod(temp,rn*ones(size(temp)));        	%ROW
    temp2 = ceil(temp./rn);                         %COLUMN
    boxmat(i,1) = min(temp1);
    boxmat(i,2) = min(temp2);
    boxmat(i,3) = max(temp1);
    boxmat(i,4) = max(temp2);
    boxmat(i,5) = (boxmat(i,3)-boxmat(i,1))*(boxmat(i,4)-boxmat(i,2));
end

%% REMOVE COMPONENTS WHOS SURROUNDING BOX AREA IS LESS THAN THE AVERAGE SURROUNDING BOX AREA

ind = mean(boxmat(:,5))/4;
for i = 1:m1
    if boxmat(i,5) < ind
        a(enough{1,i}) = 0;
        boxmat(i,:) = 0;
    end
end

%% INVERSE THE IMAGE AND SORT THE CONNECTED COMPONENTS

an = ~a;
boxmat = sortrows(boxmat,1);
i = 1;
while boxmat(i,1)==0
    i = i+1;
end
boxmat = boxmat(i:m1,:);
boxfinal = sortcol(boxmat);
m2 = size(boxfinal,1);

%% CREATE THE DATASET FOR TESTING

testmat = zeros(m2,1024);
p3=zeros(m2,2);
for i = 1:m2
temp = an(boxfinal(i,1):boxfinal(i,3),boxfinal(i,2):boxfinal(i,4));
p3(i,1)=boxfinal(i,3)-boxfinal(i,1);
p3(i,2)=boxfinal(i,4)-boxfinal(i,2);
temp = binresz(temp);
temp = temp(:);
testmat(i,:) = temp';
end

%% PREDICTING THE INITIAL VALUES

testmat = ~testmat;
p = predictnn(testmat);

%% CHECKING IF NEWLINE OR NEW WORD
%It actually checks if the letter is end of line or word and assigns 1 if
%it is end of word and 2 if it is end of line

p1 = zeros(m2,1);
for i = 1:m2-1
    p1(i) = boxfinal(i+1,2)-boxfinal(i,4);
end
m3 = find(p1>0);
ind2 = mean(p1(m3));
p2 = zeros(m2,1);
ind21 = ind2*1.1;
ind22 = ind2*(-10);
for i = 1:m2
    if p1(i)>ind21
        p2(i) = 1;
    end
    if p1(i) < ind22
        p2(i) = 2;
    end
end

%% REMOVING ERRORS IF DETECTED WITH ASPECT RATIO DETECTION
p = [p p2 p3];

x=zeros(size(p,1),1);
for i=1:size(p,1)
x(i,1)=p(i,3)/p(i,4);
end

p = [p p2 p3 x];

modifier;

%% DEFINING THE KEY

key = ['1';'2';'3';'4';'5';'6';'7';'8';'9';'A';'B';'C';'D';'E';'F';'G';...
    'H';'I';'J';'K';'L';'M';'N';'O';'P';'Q';'R';'S';'T';'U';'V';'W';'X';...
    'Y';'Z';'a';'b';'c';'d';'e';'f';'g';'h';'i';'j';'k';'l';'m';'n';'o';...
    'p';'q';'r';'s';'t';'u';'v';'w';'x';'y';'z';'0';'(';')';'-'];

%% ASK THE USER TO INPUT THE FILE NAME AND WRITE THE FILE AND SAVE

file = input('Enter the name of text file\n example aaa.txt\n','s');

fileID = fopen(file,'w');
for i = 1:length(p)
    if p(i,2)==0
        fprintf(fileID,'%1s',key(p(i,1)));
    elseif p(i,2) == 1
        fprintf(fileID,'%1s ',key(p(i,1)));
    else
        fprintf(fileID,'%1s\n',key(p(i,1)));
    end
end
fclose(fileID);
