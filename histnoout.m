function outlierTable = histnoout(data, dataName, numBins, percentiles)
    % Check if dataName is provided, if not, use a default name
    if nargin < 2 || isempty(dataName)
        dataName = 'Data';
    end

    % Check if numBins is provided, if not, use a default value
    if nargin < 3 || isempty(numBins)
        numBins = 30;
    end

    % Check if percentiles are provided, if not, use default values [5, 95]
    if nargin < 4 || isempty(percentiles)
        percentiles = [5, 95];
    end

    % Validate the percentiles input
    if numel(percentiles) ~= 2 || percentiles(1) >= percentiles(2)
        error('Percentiles must be a two-element vector with increasing values, e.g., [5, 95].');
    end

    % Calculate the specified percentiles
    pLow = prctile(data, percentiles(1));
    pHigh = prctile(data, percentiles(2));

    % Identify outliers
    outliers = data(data < pLow | data > pHigh);

    % Create bin edges based on the specified percentiles
    binEdges = linspace(pLow, pHigh, numBins);

    % Plot the histogram
    figure;
    histogram(data, 'BinEdges', binEdges);
    xlabel('Data Value');
    ylabel('Frequency');
    title(['Histogram of ', dataName, ' (', num2str(percentiles(1)), 'th-', num2str(percentiles(2)), 'th Percentile)']);

    % Display the range used for the bins
    disp(['Bin range for ', dataName, ': [', num2str(pLow), ', ', num2str(pHigh), ']']);

    % Display the outliers in a table
    if ~isempty(outliers)
        outlierTable = table(outliers, 'VariableNames', {'Outliers'});
        disp(['Outliers in ', dataName, ':']);
        disp(outlierTable);
    else
        disp(['No outliers detected in ', dataName, '.']);
    end
end
