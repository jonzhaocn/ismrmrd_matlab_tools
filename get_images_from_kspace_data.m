function images = get_images_from_kspace_data(kspace_data, data_header, pixel_value_range, contrast_rate, mask, config)
    if nargin < 2
        error('need to input parameters: kspace_data and data_header')
    end
    if nargin > 6
        error('too much parameters')
    end
    if nargin < 6
        config = struct();
    end
    if nargin < 5
        mask = 1;
    end
    if nargin < 4
        contrast_rate = 1;
    end
    if nargin < 3
        pixel_value_range = [0, 1];
    end
    
    if pixel_value_range(1) >= pixel_value_range(2)
        error('wrong pixel value range')
    end
    
    images = cell(size(kspace_data, 4), 1);
    
    % get encoding parameter from data_header
    enc_Nx = data_header.encoding.encodedSpace.matrixSize.x;
    enc_Ny = data_header.encoding.encodedSpace.matrixSize.y;
    enc_Nz = data_header.encoding.encodedSpace.matrixSize.z;
    
    if isfield(config, 'rec_Nx')
       rec_Nx = config.rec_Nx;
    else
       rec_Nx = data_header.encoding.reconSpace.matrixSize.x; 
    end
    if isfield(config, 'rec_Ny')
       rec_Ny = config.rec_Ny;
    else
       rec_Ny = data_header.encoding.reconSpace.matrixSize.y; 
    end
    if isfield(config, 'rec_Nz')
       rec_Nz = config.rec_Nz;
    else
       rec_Nz = data_header.encoding.reconSpace.matrixSize.z;
    end

    try
        nCoils = data_header.acquisitionSystemInformation.receiverChannels;
    catch
        nCoils = 1;
    end
    
    for i = 1:size(kspace_data, 4)
        K = kspace_data(:,:,:,i);
        
        % for reconstrution size larger than encoding size
        if rec_Nx > enc_Nx || rec_Ny > enc_Ny
            temp = zeros(rec_Nx, rec_Ny, nCoils, 'like', K);
            indx_1 = floor((rec_Nx - enc_Nx)/2)+1;
            indx_2 = floor((rec_Nx - enc_Nx)/2)+ enc_Nx;
            
            indy_1 = floor((rec_Ny - enc_Ny)/2)+1;
            indy_2 = floor((rec_Ny - enc_Ny)/2)+ enc_Ny;
            temp(indx_1:indx_2, indy_1:indy_2,:) = K;
            K = temp;
        end
        % apply mask in k-space data
        K = K .* mask;
        
        K = fftshift(ifft(fftshift(K,1),[],1),1);
        % Chop if needed, for oversample case in x axis
        if enc_Nx > rec_Nx
            ind1 = floor((enc_Nx - rec_Nx)/2)+1;
            ind2 = floor((enc_Nx - rec_Nx)/2)+rec_Nx;
            K = K(ind1:ind2,:,:,:);
        end
        
        K = fftshift(ifft(fftshift(K,2),[],2),2);
        if size(K,3)>1
            K = fftshift(ifft(fftshift(K,3),[],3),3);
        end
        img = sqrt(sum(abs(K).^2, 3));
        
        images{i} = img; 
    end

    images = cat(3, images{:});
    images = reshape(images, size(images, 1), size(images, 2), 1, size(images, 3));
  
    % adjust constrast and pixel value
    for i = 1:size(images, 4)
        % ---------------- orig image
        % adjust contrast
        img = images(:,:,:,i);
        img = (img - min(img(:)));
        
        max_val = max(img(:));
        img(img > contrast_rate * max_val) = contrast_rate * max_val;
        img = img / (contrast_rate * max_val);
        
        % adjust pixel value
        img = img*(pixel_value_range(2) - pixel_value_range(1)) + pixel_value_range(1);
        images(:,:,:,i) = img;
    end
end
