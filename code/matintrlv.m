function intrlvd = matintrlv(data,Nrows,Ncols)
    if isvector(data) % data is a vector
        assert(numel(data) == Nrows*Ncols);
    elseif ismatrix(data) % data is a matrix
        assert(size(data, 1) == Nrows*Ncols); % must be Nrows*Ncols rows
    end
    
    iters = size(data, 2); % Columns processed individually

    intrlvd = zeros(size(data));
    for i = 1:iters
        col = data(:, i);
        tmp_t = zeros(Ncols, Nrows);
        tmp_t(:) = col;
        
        tmp = tmp_t';
        intrlvd(:, i) = tmp(:);
    end
end