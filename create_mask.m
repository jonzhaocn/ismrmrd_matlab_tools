function [mask, sampling_rate] = create_mask(size, step, num_acs_line)
    mask = zeros(size);
    
    if numel(num_acs_line) == 1
        acs_loc = floor((size(1)-num_acs_line+2)/2):floor((size(1)+num_acs_line)/2);
        
    elseif numel(num_acs_line) == 2
        acs_loc(:,1) = floor((size(1) - num_acs_line(1)+2)/2):floor((size(1) + num_acs_line(1))/2);
        acs_loc(:,2) = floor((size(2) - num_acs_line(2)+2)/2):floor((size(2) + num_acs_line(2))/2);
    else
        error('illegal num_acs_line');
    end

    if numel(step) == 1
        sample_row = mod(0:size(1)-1, step);
        mask(sample_row==0,:,:) = 1;
        mask(acs_loc,:,:) = 1;
  
    elseif numel(step) == 2
        sample_row = mod(0:size(1)-1,step(1));
        sample_col = mod(0:size(2)-1,step(2));
        mask(sample_row==0, sample_col==0,:) = 1;
        mask(acs_loc(:,1),acs_loc(:,2),:) = 1;
    else
        error('illegal step');
    end
    
    sampling_rate = prod(size)/sum(mask(:));
    mask = logical(mask);
end

