function res = voc_eval(path, comp_id, test_set, output_dir, rm_res)

VOCopts = get_voc_opts(path);
VOCopts.testset = test_set;

for i = 1:length(VOCopts.classes)
  cls = VOCopts.classes{i};
  res(i) = voc_eval_cls(cls, VOCopts, comp_id, output_dir, rm_res);
end

fprintf('\n~~~~~~~~~~~~~~~~~~~~\n');
fprintf('Results:\n');
aps = [res(:).ap]';
% TODO: remove HP
fprintf('%.1f\n', aps * 100);
fprintf('Mean mAP: %.1f\n', mean(aps) * 100);
fprintf('~~~~~~~~~~~~~~~~~~~~\n');

all_tp = res(1).tp;
all_fp = res(1).fp;
all_npos = res(1).npos;

for i = 2:length(VOCopts.classes)
  all_tp = all_tp + res(i).tp;
  all_fp = all_fp + res(i).fp;
  all_npos = all_npos + res(i).npos;
end

all_rec = all_tp / all_npos;
all_prec = all_tp ./ (all_tp + all_fp);

all_ap=0;
for t=0:0.1:1
    p=max(all_prec(all_rec>=t));
    if isempty(p)
        p=0;
    end
    all_ap=all_ap+p;
end
all_ap = all_ap/11;

% plot overall precision/recall
plot(all_rec,all_prec,'-');
grid;
xlabel 'recall'
ylabel 'precision'
title(sprintf('overall: %s, subset: %s, AP = %.3f',cls,VOCopts.testset,all_ap));

all_ap_auc = xVOCap(all_rec, all_prec);

% force plot limits
ylim([0 1]);
xlim([0 1]);

print(gcf, '-djpeg', '-r0', ...
[output_dir '/overall_pr.jpg']);

function res = voc_eval_cls(cls, VOCopts, comp_id, output_dir, rm_res)

test_set = VOCopts.testset;
year = VOCopts.dataset(4:end);

addpath(fullfile(VOCopts.datadir, 'VOCcode'));

res_fn = sprintf(VOCopts.detrespath, comp_id, cls);

recall = [];
prec = [];
ap = 0;
ap_auc = 0;

do_eval = 1; %(str2num(year) <= 2007) | ~strcmp(test_set, 'test');
if do_eval
  % Bug in VOCevaldet requires that tic has been called first
  tic;
  [recall, prec, ap, tp, fp, npos] = VOCevaldet(VOCopts, comp_id, cls, true);
  ap_auc = xVOCap(recall, prec);

  % force plot limits
  ylim([0 1]);
  xlim([0 1]);

  print(gcf, '-djpeg', '-r0', ...
        [output_dir '/' cls '_pr.jpg']);
end
fprintf('!!! %s : %.4f %.4f\n', cls, ap, ap_auc);

res.recall = recall;
res.prec = prec;
res.ap = ap;
res.ap_auc = ap_auc;
res.tp = tp;
res.fp = fp;
res.npos = npos;

save([output_dir '/' cls '_pr.mat'], ...
     'res', 'recall', 'prec', 'ap', 'ap_auc', 'tp', 'fp', 'npos');

if rm_res
  delete(res_fn);
end

rmpath(fullfile(VOCopts.datadir, 'VOCcode'));
