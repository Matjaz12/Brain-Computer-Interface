function computeFeatures(sub, task, nFeatures, arFeatures)
% Function computes features and labels. Extracted features are saved in a
% file titled "featureVectores.txt", labels are saved in a file titled
% "referenceClass.txt". Saved files can be used to perform classification.
% Input parameters:
%       sub - name of the subject.
%       task - name of the task: Task1 (open and close left or right fist)
%       or Task2 (imagine opening and closing left or right fist).
%       nFeatures - Number of features to extract. nFeatures should be
%       devisible by 2.
%       arFeatures - Add Autoregressive features or not.
% 
% Example of a command: 
%       computeFeatures('S001', 'Task2', 4, true)

    if (nargin < 3)
        nFeatures = 2;
        arFeatures = false;
    end

    if (nargin < 4)
        arFeatures = false;
    end

    %sub = 'S001';
    %task = 'Task2';
    %nFeatures = 2;

    if mod(nFeatures, 2) ~= 0
        nFeatures = nFeatures - 1;
    end

    subject = string(sub);
    records = [];

    if (strcmp(task, "Task1"))
        records = ["03", "07", "11"];
    elseif (strcmp(task, "Task2"))
        records = ["04", "08", "12"];
    else
        fprintf("Task should be either: Task1 or Task2");
        return;
    end

    T1s = {};
    T2s = {};

    for i=1:size(records, 2)
        recName = strcat(subject, 'R', records(i), '.edf');
        recName = convertStringsToChars(recName);
        % display(recName);

        % Read record and annotations
        [sig, fs, ~] = rdsamp(recName, 1:64); % note, that the 65th channel stores the annotations
        [~, T1, T2] = getIntervals(recName, 'event', fs, size(sig, 1));

        % Transpose the sig matrix, such that the rows are the 64 channels
        % and the columns are the samples
        sig = transpose(sig);

        % Save intervals of both acitivities
        for j=1:size(T1, 1)
            start = T1(j, 1);
            stop = T1(j, 2);
            T1s{end + 1} = sig(:, start:stop);
        end

        for j=1:size(T2, 1)
            start = T2(j, 1);
            stop = T2(j, 2);
            T2s{end + 1} = sig(:, start:stop);
        end
    end

    % Compute the mixing matrix W using CSP
    [W] = f_CSP(cell2mat(T1s(1)), cell2mat(T2s(1)));

    % Remove intervals that were used for training (i.e used to estimate the matrix W)
    T1s(1) = [];
    T2s(1) = [];

    % Implement a bandpass filter (keep only the freq. in the band 8-13Hz)
    fb = [0 8 8 13 13 fs / 2] / (fs / 2);
    ints = [0 0 1 1 0 0];
    n = 35;
    a = 1;
    b = firls(n, fb, ints);

    % Transform activities T1s and T2s into componenet space.
    for i=1:size(T1s, 2)
        S_i = W * cell2mat(T1s(i));

        f_i = [];

        % Build the feature vector (take the first nFeatures / 2 rows of S_i)
        for k=1:nFeatures / 2
            f_ik = transpose(S_i(k, :));
            f_i(:, k) = f_ik;
        end

        % Build the feature vector (take the last nFeatures / 2 rows of S_i)
        % !!!BUG HERE, BUG HERE, BUG HERE (I think its fixed)!!!
        for j=1:nFeatures / 2
            f_ij = transpose(S_i(size(S_i, 1) - (j-1), :));
            f_i(:, k + j) = f_ij;
        end

        % transpose the feature vector, such that it is of shape (P x M)
        f_i = transpose(f_i);
        
        % Filter the feature vector
        f_i = filter(b, a, f_i);

        % compute AR features (only for the most dominant signals)
        p = 10;
        [a_first, ~] = arburg(f_i(1, :), p);
        [a_last, ~] = arburg(f_i(size(f_i, 1), :), p);

        % Compute the log of Var for each dimension of the feature vector
        for k=1:nFeatures
            lvT1(i, k) = log(var(f_i(k, :)));
        end

        mergedT1(i, :) = [lvT1(i, :),  [a_first, a_last]];
    end

    for i=1:size(T2s, 2)
        f_i = [];

        S_i = W * cell2mat(T2s(i));

        % Build the feature vector (take the first nFeatures / 2 rows of S_i)
        for k=1:nFeatures / 2
            f_ik = transpose(S_i(k, :));
            f_i(:, k) = f_ik;
        end

        % Build the feature vector (take the last nFeatures / 2 rows of S_i)
        for j=1:nFeatures / 2
            f_ij = transpose(S_i(size(S_i, 1) - (j-1), :));
            f_i(:, k + j) = f_ij;
        end
        % transpose the feature vector, such that it is of shape (P x M)
        f_i = transpose(f_i);
        
        % Filter the feature vector
        f_i = filter(b, a, f_i);

        % compute AR features (only for the most dominant signals)
        p = 10;
        [a_first, ~] = arburg(f_i(1, :), p);
        [a_last, ~] = arburg(f_i(size(f_i, 1), :), p);

        % Compute the log of Var for each dimension of the feature vector
        for k=1:nFeatures
            lvT2(i, k) = log(var(f_i(k, :)));
        end

        mergedT2(i, :) = [lvT2(i, :),  [a_first, a_last]];
    end

    % Display scatter plot of classes (only makes sense if nFeatures=2)
    if (nFeatures == 2)
        figure;
        scatter(lvT1(:, 1), lvT1(:, 2));
        hold on;
        scatter(lvT2(:, 1), lvT2(:, 2));
        tit
    end

    % burgs method finds vector of coefficients a, which correspond to a
    % IIR filter that has a squaared amplitude response similar to the
    % power spectrum of the input signal x.
    % we assume that the power spectrum. (or the corresponding parameters
    % a) are different for L and R motor activity. Therefore we use a and b
    % to make predictions.

    % In fact parameters of the AR model do contain all information about
    % the spectral power. AR spectrum has a higher freq. resolition than
    % FT (this is great because we are working with short intervals, using 
    % FT the freq. resolution would be low)
    
    % a ... model parameters, e ... estimated variance
    % p = 10;
    % [a, var] = arburg(x, p);

    % Save feature vectors as "featureVectors.txt" and labels "referenceClass.txt"
    
    if (arFeatures == true)
        featureVectors = [mergedT1; mergedT2];
    else
        featureVectors = [lvT1; lvT2];
    end

    classes = ["T1" + strings([size(lvT1, 1), 1]); "T2" + strings([size(lvT2, 1), 1])];
    fprintf("Extracted feature vectors\n");
    fprintf("size(featureVectors): %d x %d\n", size(featureVectors));
    fprintf("size(classes): %d x %d\n", size(classes));

    writematrix(featureVectors,'featureVectors.txt','Delimiter','space');
    writematrix(classes,'referenceClass.txt','Delimiter','space');
end