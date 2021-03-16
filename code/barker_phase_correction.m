function phOffset = barker_phase_correction(txSym, rxSym, barker)
% https://www.mathworks.com/help/comm/ref/comm.carriersynchronizer-system-object.html#bumsi6k
    idx = (1:barker.Length);
    phOffset = angle(txSym(idx) .* conj(rxSym(idx)));
%     phOffset = round((2/pi) * phOffset); % -1, 0, 1, +/-2
%     phOffset(phOffset==-2) = 2; % Prep for mean operation
    phOffset = mean((pi/2) * phOffset); % -pi/2, 0, pi/2, or pi
    disp(['Estimated mean phase offset = ',num2str(phOffset*180/pi),' degrees'])
end