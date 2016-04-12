%clear workspace in Matlab 
clear all
%close all images
close all
%clear screen
clc

%% read data of two channels from csv files.
file = csvread('RotationData/Rotation_1.csv',0,3);
data_test = file(:,[1,2]);%csvread('1127_exp_ch1.csv',0,3);
data_test1 = file(:,[3,4]);%csvread('1127_exp_ch2.csv',0,3);

%% radar parameter
%frequency starts from 2GHz
f0 = 2e9;
%center frequency 3GHz, total bandwidth 2GHz
fc = 3e9;
%speed of light
c = 3e8;
%wavelength at center frequency
lamda = c/fc;
%step frequency 20MHz
delt_f = 20e6;
%for each channel of 1GHz bandwidth, there are 50 steps
N = 50;
%data sampled at 5KHz
fs1 = 5e3;
%sampled period 0.2ms
ts1 = 1/fs1;
%each frequency step duration 1ms, so there are 5 sampled points each pulse
s_num = 5;
%50 steps, 5 points for each step, so there are 250 points in each frame
s_fram = 250.015; %instrument (signal genaretor) as reference
%total time for one frame 50ms
ts2 = ts1*s_fram;
%frame repeated frequency 20Hz
fs2 = 1/ts2;
%In experiment, data were collected for 20s, including 400 frames in total. We use 398 frames.
fram_num = 398;
%start read from this point(excel file), for each step the first two points generated by PLL are not good enough
first_sp = 3; 
%for each frequency step, only one sample point is selected
data = zeros(2,N*fram_num);
data1 = zeros(2,N*fram_num);
%% re-order data
%for each frequency step, there are 5 samples, only the 4th sample is used.
%for all 398 frames of channel 1, select the 4 samples for each step and store them
%in matrix data. One column for I and the other column for Q
for cnt = 1:2
    for cnt1 = 1:fram_num
        data_tem = data_test(round(first_sp+s_fram*(cnt1-1)):round(first_sp-1+s_fram*cnt1),cnt);
        for cnt2 = 1:N
            data(cnt,cnt2+N*(cnt1-1)) = data_tem(2+round(s_num*(cnt2-1)));
        end
    end
end
%for all 398 frames of channel 2, select the 4 the sample for each step and store them
%in matrix data1. One column for I and the other column for Q
for cnt = 1:2
    for cnt1 = 1:fram_num
        data_tem1 = data_test1(round(first_sp+s_fram*(cnt1-1)):round(first_sp-1+s_fram*cnt1),cnt);
        for cnt2 = 1:N
            data1(cnt,cnt2+N*(cnt1-1)) = data_tem1(2+round(s_num*(cnt2-1)));
        end

    end
end
%form complex values using I and Q for both channels
%vector size 50*398
data_c_tem = data(1,:)-1i*data(2,:);
data_c_tem1 = data1(1,:)-1i*data1(2,:);
%transform the vectors to matrice, matrice size 50x398
data_c = reshape(data_c_tem,N,[]);
data_c1 = reshape(data_c_tem1,N,[]);
%one channel sweeps from 2-3GHz, the other channel sweeps from 3-4GHz
%combine these two matrice together, the new matrix is 100x398, and the
%frame size is 100 now
data_c = [data_c; data_c1];
%apply hamming window to each frame
N_hamming1 = hamming(N*2)*ones(1,fram_num);
data_c = data_c.*N_hamming1;
%pulse compress
%apply ifft to each frame
%fftshift moves the zero-frequency component to the center of spectrum
ifft_num = 1024*2;
range_profile = ifft(data_c,ifft_num);
range_profile_abs = abs(range_profile);
%range resolution
delt_range = c/(2*ifft_num*delt_f);
%range axis
r_axis = (0:ifft_num-1)*delt_range;
%plot the range information using 1st frame
figure
plot(r_axis,range_profile_abs(:,1))
xlabel('range/m');
ylabel('amplitude')
title('HRRP')
% phase extraction
%find the highest peak of 1st range profile to identify the range of subject
[max_value, max_index] = max(range_profile_abs(:,1));
%extract phase information of each range profile at the range bin subject
%traversed
dis_phase = angle(range_profile(max_index,:));
%transpose the phase vector 
dis_phase_un = dis_phase';
%unwrap the phase information;
%corrects the radian phase angles by adding multiples of �2pi when absolute 
%jumps between consecutive elements are greater than or equal to the default jump tolerance of pi radians.
dis_phase_un = unwrap(dis_phase_un);
%remove the mean value of phase
dis_phase_un = dis_phase_un-mean(dis_phase_un);
%plot the phase variation
figure
plot(dis_phase_un,'k','LineWidth',2)
title('Phase Variation')
%extract displacement based on phase information
dis = dis_phase_un*lamda/4/pi*1000;
%slow time axis
dis_ax = 0:fram_num-1;
dis_ax = dis_ax*ts2;
%plot the displacement versus time
figure
plot(dis_ax,dis,'k','LineWidth',2)
xlabel('time/s')
ylabel('displacement/mm')
title('Displacement of Target')
% spectrum of vital sign
%apply fft to extracted displacement variations
fft_num = 2048;
spec = fft(dis,fft_num);
%frequency resolution in spectrum
f_resol = fs2/fft_num;
%frequency axis
f_axis = (0:fft_num/2-1)*f_resol;
%plot the spectrum
figure
plot(f_axis,abs(spec(1:fft_num/2)),'k','LineWidth',2)
xlim([0 2])
title('Spectrum of Vital Sign')

