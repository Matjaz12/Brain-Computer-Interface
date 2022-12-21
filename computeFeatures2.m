function computeFeatures(sub, task, nFeatures)
%
% Function computes features and labels. Extracted features are saved in a file titled
% "featureVectors.txt", labels are saved in file titled "referenceClass.txt". Saved
% files can be used to perform classification.
% Input parameters:
%       sub - name of the subject
%       task - name of the task, either Task1 (open and close left or right fist) 
%              or Task2 (imagine opening and closing left or right fist)
%       nFeatures - Number of features to extract, the value should be devisible by 2.
% Example of a command: 
%       computeFeatures2('S001', 'Task2', 4)

    if (nargin < 3)
        nFeatures = 2;
    end

    if ()

    nFeatures = 4;
    sub = "S001";
    task = "Task2";

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
        [sig, fs, tm] = rdsamp(recName, 1:64); % note, that the 65th channel stores the annotations
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
        f_i = [];

        S_i = W * cell2mat(T1s(i));

        % Build the feature vector (take the first nFeatures / 2 rows of S_i)
        for k=1:nFeatures / 2
            f1 = transpose(S_i(k, :));
            f_i(:, k) = f1;
        end

        % Build the feature vector (take the last nFeatures / 2 rows of S_i)
        for k=nFeatures / 2:nFeatures
            f1 = transpose(S_i(size(S_i, 1) - k, :));
            f_i(:, k) = f1;
        end

        % transpose the feature vector, such that it is of shape (P x M)
        f_i = transpose(f_i);
        
        % Filter the feature vector
        f_i = filter(b, a, f_i);

        % Compute the log of Var for each dimension of the feature vector
        for k=1:nFeatures
            lvT1(i, k) = log(var(f_i(k, :)));
        end
    end

    for i=1:size(T2s, 2)
        f_i = [];

        S_i = W * cell2mat(T2s(i));

        % Build the feature vector (take the first nFeatures / 2 rows of S_i)
        for k=1:nFeatures / 2
            f1 = transpose(S_i(k, :));
            f_i(:, k) = f1;
        end

        % Build the feature vector (take the last nFeatures / 2 rows of S_i)
        for k=nFeatures / 2:nFeatures
            f1 = transpose(S_i(size(S_i, 1) - k, :));
            f_i(:, k) = f1;
        end

        % transpose the feature vector, such that it is of shape (P x M)
        f_i = transpose(f_i);
        
        % Filter the feature vector
        f_i = filter(b, a, f_i);

        % Compute the log of Var for each dimension of the feature vector
        for k=1:nFeatures
            lvT2(i, k) = log(var(f_i(k, :)));
        end
    end

    % Display scatter plot of classes (only makes sense if nFeatures=2)
    if (nFeatures == 2)
        figure;
        scatter(lvT1(:, 1), lvT1(:, 2));
        hold on;
        scatter(lvT2(:, 1), lvT2(:, 2));
    end

    % Save feature vectors as "featureVectors.txt" and labels "referenceClass.txt"
    featureVectors = [lvT1; lvT2];
    classes = ["T1" + strings([size(lvT1, 1), 1]); "T2" + strings([size(lvT2, 1), 1])];
    fprintf("Extracted feature vectors\n");
    fprintf("size(featureVectors): %d x %d\n", size(featureVectors));
    fprintf("size(classes): %d x %d\n", size(classes));

    writematrix(featureVectors,'featureVectors.txt','Delimiter','space');
    writematrix(classes,'referenceClass.txt','Delimiter','space');
end