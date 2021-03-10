function deintrlvd = m_matdeintrlv(data,Nrows,Ncols)
    if isvector(data) % data is a vector
        assert(numel(data) == Nrows*Ncols);
    elseif ismatrix(data) % data is a matrix
        assert(size(data, 1) == Nrows*Ncols); % must be Nrows*Ncols rows
    end
    
    iters = size(data, 2); % Columns processed individually

    deintrlvd = zeros(size(data));
    for i = 1:iters
        col = data(:, i);
        tmp = zeros(Nrows, Ncols);
        tmp(:) = col;
        
        tmp_t = tmp';
        
        deintrlvd(:, i) = tmp_t(:);
    end

end