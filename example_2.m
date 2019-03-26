% this script: load k-space data from ismrmrd file or mat file, and create
% original images and noisy image according to k-space data

% ismrmrd file download from URL http://mridata.org/list
ismrmrd_file_path = 'D:\mri_data\hdf_files\stanford_fullysampled_3d_fse_knees\52c2fd53-d233-4444-8bfd-7c454240d314.h5';
intermediate_mat_file_path = 'D:\mri_data\mat_files\52c2fd53-d233-4444-8bfd-7c454240d314.mat';
result_mat_file_path = './train_mri_data.mat';
pixel_value_range = [-500, 500];
contrast_rate = 0.65; 


% convert ismrmrd to mat format
if ~exist(intermediate_mat_file_path, 'file')
    fprintf('converting ismrmrd to mat format: %s \n', ismrmrd_file_path)
    [mri_data, data_header] = convert_ISMRMRD_to_mat(ismrmrd_file_path, intermediate_mat_file_path);
    fprintf('done.\n')
else
    % read mat file
    fprintf('loading mat file: %s\n', intermediate_mat_file_path)
    load(intermediate_mat_file_path)
    fprintf('done.\n')
end

rec_Nx = data_header.encoding.reconSpace.matrixSize.x;
rec_Ny = data_header.encoding.reconSpace.matrixSize.y;
rec_Nz = data_header.encoding.reconSpace.matrixSize.z;
try
    nCoils = data_header.acquisitionSystemInformation.receiverChannels;
catch
    nCoils = 1;
end

mask_step = 3;
num_acs_line = 48;
mask = create_mask([rec_Nx, rec_Ny, nCoils], mask_step, num_acs_line);
mask = reshape(mask, rec_Nx, rec_Ny, 1, nCoils);

original_images = get_images_from_kspace_data(mri_data, data_header, pixel_value_range, contrast_rate);
noisy_images = get_images_from_kspace_data(mri_data, data_header, pixel_value_range, contrast_rate, mask);

save(result_mat_file_path, 'original_images', 'noisy_images');
fprintf('save mri_data: %s\n', result_file_path)

