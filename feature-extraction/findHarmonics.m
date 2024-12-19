function [harmonicFrequencies, harmonicIdx] = findHarmonics(peakLocations, fundamentalLocation, nHarmonics, avgSamplingFrequency, fftSize, opts)
% findHarmonics find the harmonic frequencies given a set of locations and
% location of the fundamental frequency.
%
% Inputs:
%   - peakLocations: Vector of peak locations/indices.
%   - fundamentalLocation: Index where the fundamental frequency is located.
%   - nHarmonics: Number of harmonics to look for.
%   - avgSamplingFrequency: The average sampling frequency of the corresponding
%       time series / image.
%   - fftSize: Number of points in the fft that was used.
%
% Outputs:
%   - harmonicFrequencies: Vector of the harmonic frequencies corresponding to
%       fundamental location that was passed in.
%   - harmonicIdx: Indices where the harmonics were found in peakLocations.

arguments
    peakLocations (1,:) {mustBeInteger}
    fundamentalLocation (1,1) {mustBeInteger}
    nHarmonics (1,1) {mustBeInteger}
    avgSamplingFrequency (1,1) {mustBeNumeric}
    fftSize (1,1) {mustBeInteger}
    opts.nBins {mustBeInteger} = 2;
end

harmonicBins = zeros(nHarmonics, 1, 'like', peakLocations);
harmonicIdx = zeros(nHarmonics, 1, 'like', peakLocations);

% MATLAB indexing starts at one, so we need to remove 1 from the frequency
% location to get the actual frequency index/bin
fundamentalBin = fundamentalLocation - 1;
peakBins = peakLocations - 1;

for harmonicNum = 1:nHarmonics
    theoreticalHarmonicBin = fundamentalBin * harmonicNum;

    if harmonicNum > 1
        startIdx = max(harmonicIdx(harmonicNum - 1),1);
    else
        startIdx = 1;
    end

    for peakIdx = startIdx:numel(peakLocations)

        binDiff = abs(peakBins(peakIdx) - theoreticalHarmonicBin);
        if binDiff <= opts.nBins
            % the peak is within range of the theoretical harmonic frequency.
            if harmonicBins(harmonicNum) ~= 0
                % if a potential harmonic has already been found, check if the
                % new candidate is closer than the previous candidate. Keep the 
                % candidate that is closest to the theoretical harmonic.

                previousbinDiff = abs(harmonicBins(harmonicNum) - theoreticalHarmonicBin);
                if binDiff < previousbinDiff
                    harmonicBins(harmonicNum) = peakBins(peakIdx);
                    harmonicIdx(harmonicNum) = peakIdx;
                end
            else
                % this is the first harmonic candidate we've found
                harmonicBins(harmonicNum) = peakBins(peakIdx);
                harmonicIdx(harmonicNum) = peakIdx;
            end
        end
    end
end

harmonicFrequencies = (avgSamplingFrequency / fftSize)  * harmonicBins;
