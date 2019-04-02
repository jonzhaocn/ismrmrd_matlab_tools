function [mri_data, data_header] = read_ISMRMRD(file_path)
    if exist(file_path, 'file')
        dset = ismrmrd.Dataset(file_path, 'dataset');
    else
        error(['File ' file_path ' does not exist.  Please generate it.'])
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Read some fields from the XML header %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We need to check if optional fields exists before trying to read them

    hdr = ismrmrd.xml.deserialize(dset.readxml);

    %% Encoding and reconstruction information
    % Matrix size
    enc_Nx = hdr.encoding.encodedSpace.matrixSize.x;
    enc_Ny = hdr.encoding.encodedSpace.matrixSize.y;
    enc_Nz = hdr.encoding.encodedSpace.matrixSize.z;

    % Number of slices, coils, repetitions, contrasts etc.
    % We have to wrap the following in a try/catch because a valid xml header may
    % not have an entry for some of the parameters

    try
        nSlices = hdr.encoding.encodingLimits.slice.maximum + 1;
    catch
        nSlices = 1;
    end

    try 
        nCoils = hdr.acquisitionSystemInformation.receiverChannels;
    catch
        nCoils = 1;
    end

    try
        nReps = hdr.encoding.encodingLimits.repetition.maximum + 1;
    catch
        nReps = 1;
    end

    try
        nContrasts = hdr.encoding.encodingLimits.contrast.maximum + 1;
    catch
        nContrasts = 1;
    end
    % TODO add the other possibilities

    %% Read all the data
    % Reading can be done one acquisition (or chunk) at a time, 
    % but this is much faster for data sets that fit into RAM.
    
    fprintf('read acquisition ... \n')
    D = dset.readAcquisition();
    fprintf('done.\n')
    
    % Note: can select a single acquisition or header from the block, e.g.
    % acq = D.select(5);
    % hdr = D.head.select(5);
    % or you can work with them all together

    %% Ignore noise scans
    % TODO add a pre-whitening example
    % Find the first non-noise scan
    % This is how to check if a flag is set in the acquisition header
    isNoise = D.head.flagIsSet('ACQ_IS_NOISE_MEASUREMENT');
    firstScan = find(isNoise==0,1,'first');
    if firstScan > 1
        noise = D.select(1:firstScan-1);
    else
        noise = [];
    end
    meas  = D.select(firstScan:D.getNumber);
    clear D;

    %% Reconstruct images
    % Since the entire file is in memory we can use random access
    % Loop over repetitions, contrasts, slices
    mri_data = cell(nReps * nContrasts * nSlices, 1);
    
    nimages = 1;
    for rep = 1:nReps
        for contrast = 1:nContrasts
            for slice = 1:nSlices
                % Initialize the K-space storage array
                K = zeros(enc_Nx, enc_Ny, 1, nCoils, 'like', meas.data{1});
                % Select the appropriate measurements from the data
                acqs = find(  (meas.head.idx.contrast==(contrast-1)) ...
                            & (meas.head.idx.repetition==(rep-1)) ...
                            & (meas.head.idx.slice==(slice-1)));
                        
                if isempty(acqs)
                    continue
                end
                        
                for p = 1:length(acqs)
                    ky = meas.head.idx.kspace_encode_step_1(acqs(p)) + 1;
                    kz = meas.head.idx.kspace_encode_step_2(acqs(p)) + 1;
                                        
                    K(:,ky,kz,:) = meas.data{acqs(p)};
                end
                mri_data{nimages} = K;
                nimages = nimages + 1;
            end
        end
    end
    mri_data = cat(3, mri_data{:});
    mri_data = permute(mri_data, [1,2,4,3]);
    data_header = hdr;
end