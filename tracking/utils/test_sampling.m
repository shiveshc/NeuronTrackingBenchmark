%%%% simple sampling test


x = round(10 + (100-10)*rand(10000,1));
disp(['true mean - ', num2str(mean(x))])
disp(['true median - ', num2str(median(x))])

num_samples = 25;
times_sample = 100;
levels = 2;
curr_level_mean = [];
curr_level_median = [];
for l = 1:levels
    mean_each_sample = [];
    median_each_sample = [];
    for n = 1:times_sample
        curr_sample = randperm(size(x,1),num_samples);
        curr_mean = mean(x(curr_sample,:));
        curr_median = median(x(curr_sample,:));
        mean_each_sample = [mean_each_sample;curr_mean];
        median_each_sample = [median_each_sample;curr_median];
    end
    curr_level_mean = [curr_level_mean; mean(mean_each_sample)];
    curr_level_median = [curr_level_median; median(median_each_sample)];
end
disp(['mean ', num2str(times_sample), ' times drawn of ', num2str(num_samples), ' samples each - ', num2str(mean(curr_level_mean))])
disp(['median ', num2str(times_sample), ' times drawn of ', num2str(num_samples), ' samples each - ', num2str(mean(curr_level_median))]) 