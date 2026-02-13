% Clear workspace
clc; clear; close all;

%% Step 1: Load EEG file
psg_file = 'C:\Users\lenovo\OneDrive - University of Engineering and Technology Taxila\Desktop\DSP PROJECT\Final Project\SC4001E0-PSG.EDF';
data = edfread(psg_file); % Returns a timetable in modern MATLAB

% List available channels
channel_names = data.Properties.VariableNames;
disp('Available channels:');
disp(channel_names');

% Select EEGFpz_Cz automatically
if any(contains(channel_names,'EEGFpz'))
    eeg_signal = data.EEGFpz_Cz;
else
    eeg_signal = data.(channel_names{1}); % fallback
end

fs = 100; % Sleep-EDF standard sampling frequency
disp(['Using channel: EEGFpz_Cz']);
fprintf('Sampling frequency: %d Hz\n', fs);

%% Convert to numeric and detrend
if istable(eeg_signal)
    eeg_signal = table2array(eeg_signal);
elseif iscell(eeg_signal)
    eeg_signal = cell2mat(eeg_signal);
end

eeg_signal = double(eeg_signal(:));
eeg_signal = detrend(eeg_signal);
% Calculate total recording time in hours
total_recording_time = length(eeg_signal) / fs / 3600;

%% Step 2: Define and Extract Frequency Bands
% Define frequency bands
bands = struct('Delta', [0.5 4], 'Theta', [4 8], ...
              'Alpha', [8 12], 'Beta', [12 30]);

% Initialize storage for filtered signals and power calculation
filtered_signals = struct();
band_powers = struct();

% Process each frequency band
band_names = fieldnames(bands);
for i = 1:length(band_names)
    band = band_names{i};
    freq_range = bands.(band);
    
    % Design Butterworth bandpass filter
    [b, a] = butter(4, freq_range/(fs/2), 'bandpass');
    
    % Apply filter
    filtered_signals.(band) = filtfilt(b, a, eeg_signal);
end

%% Step 3: Sleep Stage Detection using Sliding Window
window_size = 30 * fs; % 30 seconds of data
overlap = 0.5;    % 50% overlap
window_samples = window_size;
overlap_samples = floor(window_samples * overlap);

% Initialize sleep_stages array
sleep_stages = {};
num_windows = floor((length(eeg_signal) - window_samples) / overlap_samples);

% Initialize array to store power values for each epoch
epoch_powers = zeros(num_windows, length(band_names));

% Process each window
for w = 1:num_windows
    start_idx = (w - 1) * overlap_samples + 1;
    end_idx = start_idx + window_samples - 1;
    
    % Extract current window signal
    window_signal = eeg_signal(start_idx:end_idx);
    
    % Calculate band powers for the current window
    window_band_powers = struct();
    for i = 1:length(band_names)
        band = band_names{i};
        window_band_powers.(band) = bandpower(window_signal, fs, bands.(band));
        epoch_powers(w,i) = window_band_powers.(band);
    end
    
    % Sleep Stage Classification based on band power thresholds
    delta_power = window_band_powers.Delta;
    theta_power = window_band_powers.Theta;
    alpha_power = window_band_powers.Alpha;
    beta_power = window_band_powers.Beta;
    
    if beta_power > 0.2 * (delta_power + theta_power + alpha_power)
        sleep_stage = 'Wake';
    elseif theta_power > 0.2 * (delta_power + alpha_power)
        sleep_stage = 'REM';
    elseif delta_power > 0.2 * (theta_power + alpha_power + beta_power)
        if delta_power > 0.5 * (theta_power + alpha_power)
            sleep_stage = 'N3';
        else
            sleep_stage = 'N2';
        end
    else
        sleep_stage = 'N1';
    end
    
    sleep_stages{w} = sleep_stage;
end

% Convert sleep_stages to column vector
sleep_stages = sleep_stages(:);

%% Calculate Sleep Statistics
total_epochs = length(sleep_stages);
stage_counts = struct();
stage_percentages = struct();
unique_stages = unique(sleep_stages);

% Calculate counts and percentages
for stage = unique_stages'
    stage_counts.(stage{1}) = sum(strcmp(sleep_stages, stage{1}));
    stage_percentages.(stage{1}) = (stage_counts.(stage{1}) / total_epochs) * 100;
end

% Calculate stage transitions
transitions = zeros(length(unique_stages));
transition_matrix = array2table(transitions, 'RowNames', unique_stages, 'VariableNames', unique_stages);

for i = 1:length(sleep_stages)-1
    current_stage = sleep_stages{i};
    next_stage = sleep_stages{i+1};
    if ~strcmp(current_stage, next_stage)
        transition_matrix{current_stage, next_stage} = transition_matrix{current_stage, next_stage} + 1;
    end
end

%% Plot Results
% Create figure with multiple subplots
figure('Position', [100 100 1200 800]);

% 1. Hypnogram
subplot(3,2,[1,2]);
time_vector = linspace(0, total_recording_time, length(sleep_stages));
stage_values = zeros(length(sleep_stages), 1);
for i = 1:length(sleep_stages)
    switch sleep_stages{i}
        case 'Wake'
            stage_values(i) = 5;
        case 'REM'
            stage_values(i) = 4;
        case 'N1'
            stage_values(i) = 3;
        case 'N2'
            stage_values(i) = 2;
        case 'N3'
            stage_values(i) = 1;
    end
end

stairs(time_vector, stage_values, 'LineWidth', 1.5);
ylim([0.5 5.5]);
yticks(1:5);
yticklabels({'N3', 'N2', 'N1', 'REM', 'Wake'});
xlabel('Time (hours)');
ylabel('Sleep Stage');
title('Sleep Stage Detection');
xlim([0 total_recording_time]);
grid on;

% 2. Sleep Stage Distribution (Pie Chart)
subplot(3,2,3);
stage_percentages_values = cell2mat(struct2cell(stage_percentages));
pie(stage_percentages_values);
legend(unique_stages, 'Location', 'bestoutside');
title('Sleep Stage Distribution');

% 3. Power Spectral Density
subplot(3,2,4);
hold on;
colors = {'b', 'r', 'g', 'm'};
for i = 1:length(band_names)
    [pxx, f] = pwelch(filtered_signals.(band_names{i}), hamming(fs), [], [], fs);
    plot(f, 10*log10(pxx), colors{i}, 'LineWidth', 1.5);
end
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
title('Power Spectral Density');
legend(band_names);
grid on;

% 4. Stage Transition Matrix
subplot(3,2,5);
imagesc(table2array(transition_matrix));
colorbar;
title('Stage Transition Matrix');
xticks(1:length(unique_stages));
yticks(1:length(unique_stages));
xticklabels(unique_stages);
yticklabels(unique_stages);
colormap('hot');

% 5. Text Summary
subplot(3,2,6);
axis off;
text_str = {
    '\bf Sleep Analysis Summary:', ...
    sprintf('Total recording time: %.2f hours', total_recording_time), ...
    sprintf('Total epochs analyzed: %d', total_epochs), ...
    '', ...
    '\bf Stage Statistics:'
};

% Add counts and percentages for each stage
for stage = unique_stages'
    text_str{end+1} = sprintf('%s: %d epochs (%.1f%%)', ...
        stage{1}, ...
        stage_counts.(stage{1}), ...
        stage_percentages.(stage{1}));
end

% Add text to plot
text(0.1, 0.9, text_str, 'VerticalAlignment', 'top', ...
    'Units', 'normalized', 'FontSize', 10);

%% Print Detailed Statistics to Command Window
fprintf('\n=== Sleep Stage Analysis Results ===\n');
fprintf('Total recording time: %.2f hours\n', total_recording_time);
fprintf('Total epochs analyzed: %d\n\n', total_epochs);

fprintf('Sleep Stage Statistics:\n');
fprintf('------------------------\n');
for stage = unique_stages'
    fprintf('%s:\n', stage{1});
    fprintf('  Count: %d epochs\n', stage_counts.(stage{1}));
    fprintf('  Percentage: %.1f%%\n', stage_percentages.(stage{1}));
    fprintf('------------------------\n');
end

fprintf('\nTransition Matrix:\n');
disp(transition_matrix);

% Save results
results = struct();
results.total_recording_time = total_recording_time;
results.total_epochs = total_epochs;
results.stage_counts = stage_counts;
results.stage_percentages = stage_percentages;
results.transition_matrix = transition_matrix;
results.sleep_stages = sleep_stages;
results.epoch_powers = epoch_powers;
results.band_names = band_names;
save('sleep_stage_results.mat', 'results');