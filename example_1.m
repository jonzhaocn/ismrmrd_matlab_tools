% this script: load k-space data from ismrmrd file or mat file, and convert
% k-space data to image, save images in the result_save_dir

% ismrmrd file download from URL http://mridata.org/list
ismrmrd_file_path = 'D:\mri_data\hdf_files\stanford_fullysampled_3d_fse_knees\52c2fd53-d233-4444-8bfd-7c454240d314.h5';
mat_file_path = 'D:\mri_data\mat_files\52c2fd53-d233-4444-8bfd-7c454240d314.mat';
result_save_dir = './stanford_fullysampled_3d_fse_knees_results';

% convert ismrmrd to mat format
if ~exist(mat_file_path, 'file')
    fprintf('converting ismrmrd to mat format: %s \n', ismrmrd_file_path)
    [mri_data, data_header] = convert_ISMRMRD_to_mat(ismrmrd_file_path, mat_file_path);
    fprintf('done.\n')
else
    % read mat file
    fprintf('loading mat file: %s\n', mat_file_path)
    load(mat_file_path)
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
    img = img/max(img(:));
    
    imwrite(img, img_name);
    fprintf('save image: %s\n', img_name);
end
