function [mask, sampling_rate] = create_random_mask(mask_image_path, num_coils)
    mask = imread(mask_image_path);
    mask = repmat(mask', [1 1 num_coils]);
    sampling_rate = sum(mask(:))/numel(mask);
    mask = logical(mask);
end