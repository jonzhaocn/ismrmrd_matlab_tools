% ismrmrd file download from URL http://mridata.org/list
ismrmrd_file_path = 'stanford_fullysampled_3d_fse_knees.h5';
mat_file_path = 'stanford_fullysampled_3d_fse_knees.mat';
result_save_dir = './stanford_fullysampled_3d_fse_knees_results';

% convert ismrmrd to mat format
if ~exist(mat_file_path, 'file')
    [mri_data, data_header] = convert_ISMRMRD_to_mat(ismrmrd_file_path, mat_file_path);
else
    % read mat file
    fprintf('loading mat file...\n')
    load(mat_file_path)
    fprintf('done.\n')
end

% get encoding parameter from data_header
enc_Nx = data_header.encoding.encodedSpace.matrixSize.x;
enc_Ny = data_header.encoding.encodedSpace.matrixSize.y;
enc_Nz = data_header.encoding.encodedSpace.matrixSize.z;

if ~exist(result_save_dir, 'dir')
    mkdir(result_save_dir);
end

% reconstruct image from kspace data
for i = 1:size(mri_data, 1)
    % read image from mri_data
    K = mri_data{i};
    
    K = fftshift(ifft(fftshift(K,1),[],1),1);
    K = fftshift(ifft(fftshift(K,2),[],2),2);
    
    if size(K,3)>1
        K = fftshift(ifft(fftshift(K,3),[],3),3);
    end
    images = sqrt(sum(abs(K).^2, 4));
    
    for j = 1:enc_Nz
        img = images(:, :, j);
        img_name = fullfile(result_save_dir, sprintf('recon_image_%d.png', (i-1)*enc_Nz + j));
        img = (img - min(img(:))) / max(img(:));
        imwrite(img, img_name);
        fprintf('save image: %s\n', img_name);
    end
end
