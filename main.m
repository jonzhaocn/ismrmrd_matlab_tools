% ismrmrd file download from URL http://mridata.org/list
ismrmrd_file_path = 'knees.h5';
mat_file_path = 'knees.mat';
result_save_dir = './results';

% convert ismrmrd to mat format
if ~exist(mat_file_path, 'file')
    convert_ISMRMRD_to_mat(ismrmrd_file_path, mat_file_path)   
end

% read mat file
fprintf('loading mat file...')
load(mat_file_path)
fprintf('done.')

% get encoding parameter from data_header
enc_Nx = data_header.encoding.encodedSpace.matrixSize.x;
enc_Ny = data_header.encoding.encodedSpace.matrixSize.y;
enc_Nz = data_header.encoding.encodedSpace.matrixSize.z;

% reconstruct image from kspace data
for i = 1:enc_Nz:size(mri_data, 3)
    % read image from mri_data
    K = mri_data(:, :, i*(1:enc_Nz), :);
    
    K = fftshift(ifft(fftshift(K,1),[],1),1);
    K = fftshift(ifft(fftshift(K,2),[],2),2);
    
    if size(K,3)>1
        K = fftshift(ifft(fftshift(K,3),[],3),3);
    end
    image = sqrt(sum(abs(K).^2,4));
    
    if ~exist(result_save_dir, 'dir')
        mkdir(result_save_dir);
    end
        
    image_name = fullfile(result_save_dir, sprintf('recon_image_%d.png', i));
    image = (image - min(image(:))) / max(image(:));
    imwrite(image, image_name);
    fprintf('save image: %s\n', image_name);
end
