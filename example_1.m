% this script: load k-space data from ismrmrd file or mat file, and convert
% k-space data to image, save images in the result_save_dir
clc;
clear;

% ismrmrd file download from URL http://mridata.org/list
% ismrmrd_file_path = 'D:\mri_data\hdf_files\stanford_fullysampled_3d_fse_knees\52c2fd53-d233-4444-8bfd-7c454240d314.h5';
% mat_file_path = 'D:\mri_data\mat_files\52c2fd53-d233-4444-8bfd-7c454240d314.mat';
% result_save_dir = './stanford_fullysampled_3d_fse_knees_results';
ismrmrd_file_path = 'D:\mri_data\hdf_files\stanford_2d_fse\7b2c6a8a-0cff-4eb1-84ed-7dd490563181.h5';
intermediate_mat_file_path = './7b2c6a8a-0cff-4eb1-84ed-7dd490563181.mat';
result_save_dir = './stanford_2d_fse';
contrast_rate = 0.65;

% convert ismrmrd to mat format
if ~exist(intermediate_mat_file_path, 'file')
    fprintf('converting ismrmrd to mat format: %s \n', ismrmrd_file_path)
    [mri_data, data_header] = read_ISMRMRD(ismrmrd_file_path);
    fprintf('save intermediate mat: %s \n', intermediate_mat_file_path)
    save(intermediate_mat_file_path, 'mri_data', 'data_header', '-v7.3')
    fprintf('done.\n')
else
    % read mat file
    fprintf('loading mat file: %s\n', intermediate_mat_file_path)
    load(intermediate_mat_file_path)
    fprintf('done.\n')
end
images = get_images_from_kspace_data(mri_data, data_header);

if ~exist(result_save_dir, 'dir')
    mkdir(result_save_dir);
end

% save image to dir
for i = 1:size(images, 4)
    img = images(:, :, :, i);
    img_name = fullfile(result_save_dir, sprintf('recon_image_%d.png', i));
    
    img = (img - min(img(:)));
    max_val = max(img(:));
    img(img > contrast_rate * max_val) = contrast_rate * max_val;
    img = img / (contrast_rate * max_val);
    
    imwrite(img, img_name);
    fprintf('save image: %s\n', img_name);
end
