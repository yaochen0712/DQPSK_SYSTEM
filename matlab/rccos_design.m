% 这里CRC码率取巧为1/2所以比较好计算,有R_s = GPIO_SampleRate

% 1. Define filter parameters
coe_file = 'rccos_16bit_72M_6x.coe';
sample_rate = 72e6;
alpha = 0.5;   % Roll-off factor
span = 4;      % Filter span in symbols. Order = span * sps
sps = 6;       % Samples per symbol, 80M / 20M = 4 这里

% 2. Generate root raised cosine (RRC) filter coefficients
% Tx/Rx usually both use RRC; their cascade is equivalent to RC.
b_rrc = rcosdesign(alpha, span, sps, 'normal');

% 3. Save 16-bit quantized coefficients in COE format
bit_width = 16;
max_val = 2^(bit_width - 1) - 1;
min_val = -2^(bit_width - 1);

% Keep 10% headroom so the largest tap does not hit full scale.
q16_scale_factor = (max_val * 0.9) / max(abs(b_rrc));
b_rrc_q16 = round(b_rrc * q16_scale_factor);
b_rrc_q16 = min(max(b_rrc_q16, min_val), max_val);

% DC gain after 16-bit quantization. The first value is back-scaled to the
% floating-point coefficient domain; the second is the raw integer tap sum.
dc_gain_q16 = sum(double(b_rrc_q16)) / q16_scale_factor;
dc_gain_q16_int = sum(double(b_rrc_q16));

fid = fopen(coe_file, 'w');
assert(fid > 0, 'Failed to open %s for writing.', coe_file);
fprintf(fid, 'RADIX = 10;\n');
fprintf(fid, 'COEFDATA =\n');
for idx = 1:numel(b_rrc_q16)
    if idx < numel(b_rrc_q16)
        fprintf(fid, '%d,\n', b_rrc_q16(idx));
    else
        fprintf(fid, '%d;\n', b_rrc_q16(idx));
    end
end
fclose(fid);

fprintf('16-bit quantized DC gain = %.12f\n', dc_gain_q16);
fprintf('16-bit integer sum       = %d\n', dc_gain_q16_int);
fprintf('16-bit COE saved to      = %s\n', coe_file);

% 4. View frequency response with the real sample rate
if usejava('desktop')
    fvtool(b_rrc, 1, 'Fs', sample_rate);
end
