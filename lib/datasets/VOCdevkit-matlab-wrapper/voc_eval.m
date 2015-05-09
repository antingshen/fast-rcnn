function res = voc_eval(path, comp_id, test_set, output_dir, rm_res)

VOCopts = get_voc_opts(path);
VOCopts.testset = test_set;

for i = 1:length(VOCopts.classes)
  cls = VOCopts.classes{i};
  if strcmp(cls, 'hp')
    continue
  end
  res(i) = voc_eval_cls(cls, VOCopts, comp_id, output_dir, rm_res);
  % res(i) = load([output_dir '/' cls '_pr.mat']);
end

fprintf('\n~~~~~~~~~~~~~~~~~~~~\n');
fprintf('AP Results:\n');
aps = [res(:).ap]';

current_cls = 1;
for i=1:size(aps, 1)
  cls = VOCopts.classes{current_cls};
  if strcmp(cls, 'hp')
    current_cls = current_cls + 1;
    cls = VOCopts.classes{current_cls};
  end
  fprintf('%s: %.1f\n', cls, aps(i) * 100);
  current_cls = current_cls + 1;
end

fprintf('mAP: %.1f\n', mean(aps) * 100);
fprintf('~~~~~~~~~~~~~~~~~~~~\n');

all_tp_map = res(1).tp_map;
all_fp_map = res(1).fp_map;
all_npos = res(1).npos;

for i = 2:length(VOCopts.classes)
  cls = VOCopts.classes{i};
  if strcmp(cls, 'hp')
    continue
  end
  current = res(i);
  current_keys = keys(current.tp_map);
  for j=1:length(current_keys)
    key = current_keys{j};
    if ~isKey(all_tp_map, key)
      all_tp_map(key) = 0;
      all_fp_map(key) = 0;
    end
    all_tp_map(key) = all_tp_map(key) + current.tp_map(key);
    all_fp_map(key) = all_fp_map(key) + current.fp_map(key);
  end
  all_npos = all_npos + current.npos;
end

[sc1, si1] = sort(-cell2mat(keys(all_tp_map)));
all_tp = cell2mat(values(all_tp_map));
all_tp = cumsum(all_tp(si1));

[sc2, si2] = sort(-cell2mat(keys(all_fp_map)));
all_fp = cell2mat(values(all_fp_map));
all_fp = cumsum(all_fp(si2));

all_rec = (all_tp / all_npos)';
all_prec = (all_tp ./ (all_tp + all_fp))';

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
title(sprintf('overall, subset: %s, AP = %.3f',VOCopts.testset,all_ap));

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
  [recall, prec, ap, tp_map, fp_map, npos] = VOCevaldet(VOCopts, comp_id, cls, true);
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
res.tp_map = tp_map;
res.fp_map = fp_map;
res.npos = npos;

save([output_dir '/' cls '_pr.mat'], ...
     'res', 'recall', 'prec', 'ap', 'ap_auc', 'tp_map', 'fp_map', 'npos');

if rm_res
  delete(res_fn);
end

rmpath(fullfile(VOCopts.datadir, 'VOCcode'));
