function FTaquisition (wavelength1, wavelength2,TuningFreq, samples, samRate)
%FTaquisition is a function written by Austin Ferro (Cheadle lab). 
% 10/26/22
%..........................................................................
% REQUIERMENTS: 
% Matlab version 2019 or higher (for serialport function)
% Instrument Control Toolbox Matlab package
% ScanImage (MBF Bioscience 2022 with Waveform generator)
% A Waveform generator named FastTune
% TTL connections to trigger acquisition start, stop, file markers, fast
% tuning and the end of acquisition. Plase note the DIO ports that are used
% in this function, and users may need to change which ports to call (using
% dabs.resources.ResourceStore()) depending on your breakout-box set up.
% .........................................................................
% This function allows a user to trigger both the Tiberius (ThorLabs)
% laser's fast tuning function between wavelength 1 and 2 concurrently with
% the start of an acquisition loop. Tuning frequency (tuningFreq) is not
% online as a modifiable input yet as I am unsure how to incorporate the 
% waveformgenerator into this function, so please modify the waveform in 
% ScanImages' waveform generator (FastTune) to modify the period. 
%.......................................................................... 
%Note to users, please note the power disparity between wavelengths to
%ensure you reduce chances of sample and or PMT damage. See
%https://www.thorlabs.com/newgrouppage9.cfm?objectgroup_id=8323 for
%Tiberius output (mW) at different wavelengths. 

%Sets sampling rate (volumes or samples/ second) 
%Make sure your volume acquisition is less than your sampling rate
if nargin < 5 || isempty(samRate)
    samRate = 60;
end

%Set the number of samples you wish to acquire. Need to set
%the acquisitions (Acqs) equal to this number in the Main Control GUI of
%Scanimage
if nargin < 4 || isempty(samples)
    samples = 30;
end

%Set tuning period (TuningFreq) to match either your frame aquisition
%frequency for the best image. By doing so, you can drop frames from the
%final image that use the less efficient wavelength. OR use 1/n, where n is
%an odd number of the frequency of frame acquisition. By doing so, and
%averaging by any number divisible by 2, the resultant average frame should
%be equally excited by both wavelengths.

%Note mismatches in tuning frequency can cause artifacts upon averaging. 
%by doing so, make sure you are sampling any given frame with a number
%divisible by 2 so that the average of the excitation triplets is equal 
%between wavelengths.   

if nargin < 3 || isempty(TuningFreq)
    TuningFreq = 0.00762; % 1024 Frequency = 15.24Hz
end

%Set wavelengths to 980 and 1020nm if none are given to
%excite eGFP/gCamp and a red fluorophore (tdTomato/Rgeco)
if nargin < 2 || isempty(wavelength2)
    wavelength2 = 1020;
end

if nargin < 1 || isempty(wavelength1)
    wavelength1 = 980;
end

%Convert wavelengths to string as means of communicating with the Tiberius
%control box (Tiberius commands are in ASCII)
w1 = string(wavelength1);
w2 = string(wavelength2);
w = strcat("SEQ=",w1,",",w2);

%Initiate communications with the tiberius control box using the serialport
%function 
s=serialport('COM5', 19200, FlowControl="software");
configureTerminator(s,"CR/LF");
writeline(s,w); %Initiates sequencing 
writeline(s,"S=1"); %Opens Tiberius shutter

%Call waveform generator 
rs =dabs.resources.ResourceStore();
ft=rs.filterByName('FastTune');

%Setting up the vDAQ for TTL triggering 
Oport=rs.filterByName('/vDAQ0/D0.0'); %On acquisition marker
Fport=rs.filterByName('/vDAQ0/D1.2'); %Stop acquisition marker
Nport=rs.filterByName('/vDAQ0/D1.4'); %Next file marker

%Set up for aquisition parameters 
    %You may just need to do this in the main controls/ z stack

startTask(ft); %Starts the FastTune waveform generator 


%Begin acquisition loop with a wait time of your sampling rate 
for j = 1:samples

    Oport.setValue(true); %begins acquisition and starts Fast tuning 
    Oport.setValue(false);
    
    WaitSecs(samRate); 
    
    Nport.setValue(true);
    Nport.setValue(false);
    
end

stopTask(ft);

stopTask(ft);
Fport.setValue(true);
Fport.setValue(false);
writeline(s,"SEQ=0"); %Turns off sequencing 
writeline(s,"S=0");%Closes shutter 
delete(s);
sca;


