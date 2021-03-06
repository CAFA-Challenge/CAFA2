function [] = cafa_driver_result(eval_dir, reg, naive, blast, scheme)
%CAFA_DRIVER_RESULT CAFA driver result
%
% [] = CAFA_DRIVER_RESULT(eval_dir, reg, naive, blast, scheme);
%
%   Generates results for evaluation (plots, and sheets), according to the
%   evaluation configuration file '<eval_dir>/eval_config.job'.
%
% CAFA2
% |-- ! bootstrap/        (bootstrap indices for reproducibility)
% |-- ! evaluation/       (evaluation results)
% |     |-- ...
% |     `-- <eval_dir>    (which needs to be given as input. Also, any plots
% |                        generated by this function goes here.)
% `-- ! register/         (register files)
%       `-- <reg>         (the register file, needs to be given)
%
% folders marked with ! need to be prepared as prerequisites.
%
% Input
% -----
% [char]
% eval_dir:   The directory that contains evaluation results.
%
% [char]
% reg:        The team register file.
%             See cafa_team_register.m
%
% [char]
% naive:      The model ID of naive baseline. E.g. BN1S
%
% [char]
% blast:      The model ID of blast baseline. E.g. BB1S
%
% [char]
% scheme:     The running scheme, must be one of the following:
%             'paper' only generates figures in the main paper of the CAFA manuscript
%                     yaxis_fmax is set to [0.0, 0.8, 0.1]
%                     use "display name" for methods.
%
%             'suppl' only generates figures in the supplementary of the CAFA manuscript
%                     yaxis_fmax is set to [] (adaptive)
%                     use "display name" for methods.
%
%             'all'   generates all figures and sheets/tables
%                     yaxis_fmax is set to [] (adaptive)
%                     use "dump name" for methods.
%
% Output
% ------
% None.
%
% Results (if any) will be saved to <eval_dir>.
%
% Dependency
% ----------
%[>]cafa_parse_config.m
%[>]cafa_collect.m
%[>]cafa_sel_top_seq_prcurve.m
%[>]cafa_sel_top_seq_rmcurve.m
%[>]cafa_sel_top_seq_fmax.m
%[>]cafa_sel_top_seq_smin.m
%[>]cafa_plot_seq_prcurve.m
%[>]cafa_plot_seq_rmcurve.m
%[>]cafa_barplot_seq_fmax.m
%[>]cafa_barplot_seq_smin.m
%[>]cafa_sheet_seq_fmax.m
%[>]cafa_sheet_seq_smin.m
%[>]cafa_sel_top_term_auc.m
%[>]cafa_sel_valid_term_auc.m
%[>]cafa_get_term_auc.m
%[>]cafa_team_register.m

  % set-up {{{
  plot_ext  = '.png'; % recommend PNG. (EPS may also work)
  sheet_ext = '.csv'; % recommend CSV. (plain-text)

  eval_dir = regexprep(strcat(eval_dir, '/'), '//', '/');
  config_file = strcat(eval_dir, 'eval_config.job');
  config = cafa_parse_config(config_file);
  saveto_prefix = strcat(regexprep(config.eval_dir, '.*/(.*)/$', '$1'), '_');

  if strcmp(scheme, 'paper')
    yaxis_fmax = [0.0, 0.8, 0.1];
    yaxis_auc  = [];
    isdump     = false;
  elseif strcmp(scheme, 'suppl')
    yaxis_fmax = [];
    yaxis_auc  = [];
    isdump     = false;
  elseif strcmp(scheme, 'all')
    yaxis_fmax = [];
    yaxis_auc  = [];
    isdump     = true;
  elseif strcmp(scheme, 'test')
    yaxis_fmax = [];
    yaxis_auc  = [];
    isdump     = false;
  else
    error('unknown running scheme [%s].', scheme);
  end

  if strcmp(config.ont, 'mfo')
    ont_str = 'Molecular Function';
  elseif strcmp(config.ont, 'bpo')
    ont_str = 'Biological Process';
  elseif strcmp(config.ont, 'cco')
    ont_str = 'Cellular Component';
  elseif strcmp(config.ont, 'hpo')
    ont_str = 'Human Phenotype';
  else
    error('cafa_driver_result:BadOnt', 'Unknown ontology in the config.');
  end
  % }}}

  % top10 precision-recall curve {{{
  if config.do_seq_fmax && (strcmp(scheme, 'suppl') || strcmp(scheme, 'all'))
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_fmax_curve', plot_ext);
    prcurves = cafa_collect(config.eval_dir, 'seq_prcurve');
    [top10, baseline] = cafa_sel_top_seq_prcurve(10, prcurves, naive, blast, reg, isdump);
    if ~isempty(top10)
      cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline);
    end

    % mark alternative points {{{
    % rmcurves = cafa_collect(config.eval_dir, 'seq_rmcurve');
    % [top10, baseline] = cafa_sel_top_seq_prcurve(10, prcurves, naive, blast, reg, isdump, rmcurves);
    % cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline, true);
    % }}}
  end
  % }}}

  % all Fmax sheet {{{
  if config.do_seq_fmax && strcmp(scheme, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_fmax_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_fmax_sheet_disclosed', sheet_ext);
    fmaxs = cafa_collect(config.eval_dir, 'seq_fmax');
    fmaxs_bst = cafa_collect(config.eval_dir, 'seq_fmax_bst');
    cafa_sheet_seq_fmax(saveto_A, fmaxs, fmaxs_bst, reg, isdump, true);
    cafa_sheet_seq_fmax(saveto_N, fmaxs, fmaxs_bst, reg, isdump, false);
  end
  % }}}

  % top10 weighted precision-recall curve {{{
  if config.do_seq_wfmax && ((strcmp(scheme, 'suppl') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) || strcmp(scheme, 'all'))
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_wfmax_curve', plot_ext);
    prcurves = cafa_collect(config.eval_dir, 'seq_wprcurve');
    [top10, baseline] = cafa_sel_top_seq_prcurve(10, prcurves, naive, blast, reg, isdump);
    if ~isempty(top10)
      cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline);
    end
  end
  % }}}

  % all weighted Fmax sheet {{{
  if config.do_seq_wfmax && strcmp(scheme, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_wfmax_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_wfmax_sheet_disclosed', sheet_ext);
    fmaxs = cafa_collect(config.eval_dir, 'seq_wfmax');
    fmaxs_bst = cafa_collect(config.eval_dir, 'seq_wfmax_bst');
    cafa_sheet_seq_fmax(saveto_A, fmaxs, fmaxs_bst, reg, isdump, true);
    cafa_sheet_seq_fmax(saveto_N, fmaxs, fmaxs_bst, reg, isdump, false);
  end
  % }}}

  % top10 RU-MI curve {{{
  if config.do_seq_smin && strcmp(scheme, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_smin_curve', plot_ext);
    rmcurves = cafa_collect(config.eval_dir, 'seq_rmcurve');
    [top10, baseline] = cafa_sel_top_seq_rmcurve(10, rmcurves, naive, blast, reg, isdump);
    if ~isempty(top10)
      cafa_plot_seq_rmcurve(saveto, ont_str, top10, baseline);
    end
  end
  % }}}

  % all Smin sheet {{{
  if config.do_seq_smin && strcmp(scheme, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_smin_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_smin_sheet_disclosed', sheet_ext);
    smins = cafa_collect(config.eval_dir, 'seq_smin');
    smins_bst = cafa_collect(config.eval_dir, 'seq_smin_bst');
    cafa_sheet_seq_smin(saveto_A, smins, smins_bst, reg, isdump, true);
    cafa_sheet_seq_smin(saveto_N, smins, smins_bst, reg, isdump, false);
  end
  % }}}

  % top10 normalized RU-MI curve {{{
  if config.do_seq_nsmin && ((strcmp(scheme, 'suppl') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) || strcmp(scheme, 'all'))
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_nsmin_curve', plot_ext);
    rmcurves = cafa_collect(config.eval_dir, 'seq_nrmcurve');
    [top10, baseline] = cafa_sel_top_seq_rmcurve(10, rmcurves, naive, blast, reg, isdump);
    if ~isempty(top10)
      cafa_plot_seq_rmcurve(saveto, ont_str, top10, baseline);
    end
  end
  % }}}

  % all normalized Smin sheet {{{
  if config.do_seq_nsmin && strcmp(scheme, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_nsmin_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_nsmin_sheet_disclosed', sheet_ext);
    smins = cafa_collect(config.eval_dir, 'seq_nsmin');
    smins_bst = cafa_collect(config.eval_dir, 'seq_nsmin_bst');
    cafa_sheet_seq_smin(saveto_A, smins, smins_bst, reg, isdump, true);
    cafa_sheet_seq_smin(saveto_N, smins, smins_bst, reg, isdump, false);
  end
  % }}}

  % top10 Fmax bar {{{
  if config.do_seq_fmax && (strcmp(scheme, 'paper') || strcmp(scheme, 'suppl') || strcmp(scheme, 'all'))
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_fmax_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'fmax_team.txt');
    fmaxs = cafa_collect(config.eval_dir, 'seq_fmax_bst');
    [top10, baseline, info] = cafa_sel_top_seq_fmax(10, fmaxs, naive, blast, reg, isdump);
    if ~isempty(top10)
      cafa_barplot_seq_fmax(saveto, ont_str, top10, baseline, yaxis_fmax);
      save_team_info(saveto_team, info, reg);
    end
  end
  % }}}

  % top10 weighted Fmax bar {{{
  if config.do_seq_wfmax && strcmp(scheme, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_wfmax_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'wfmax_team.txt');
    fmaxs = cafa_collect(config.eval_dir, 'seq_wfmax_bst');
    [top10, baseline, info] = cafa_sel_top_seq_fmax(10, fmaxs, naive, blast, reg, isdump);
    cafa_barplot_seq_fmax(saveto, ont_str, top10, baseline, yaxis_fmax);
    save_team_info(saveto_team, info, reg);
  end
  % }}}

  % top10 Smin bar {{{
  if config.do_seq_smin && ((strcmp(scheme, 'paper') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) || strcmp(scheme, 'all'))
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_smin_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'smin_team.txt');
    smins = cafa_collect(config.eval_dir, 'seq_smin_bst');
    [top10, baseline, info] = cafa_sel_top_seq_smin(10, smins, naive, blast, reg, isdump);
    if ~isempty(top10)
      cafa_barplot_seq_smin(saveto, ont_str, top10, baseline);
      save_team_info(saveto_team, info, reg);
    end
  end
  % }}}

  % top10 normalized Smin bar {{{
  if config.do_seq_nsmin && strcmp(scheme, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_nsmin_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'nsmin_team.txt');
    smins = cafa_collect(config.eval_dir, 'seq_nsmin_bst');
    [top10, baseline, info] = cafa_sel_top_seq_smin(10, smins, naive, blast, reg, isdump);
    if ~isempty(top10)
      cafa_barplot_seq_smin(saveto, ont_str, top10, baseline);
      save_team_info(saveto_team, info, reg);
    end
  end
  % }}}

  % averaged AUC (over all teams) {{{
  if config.do_term_auc && ((strcmp(scheme, 'paper') && strcmp(config.ont, 'hpo')) || strcmp(scheme, 'all'))
    saveto = strcat(config.eval_dir, saveto_prefix, 'avg_auc_bar', plot_ext);
    aucs = cafa_collect(config.eval_dir, 'term_auc');

    % % load term acc <--> term name table
    % fid = fopen(config.ont_term, 'r');
    % terms = textscan(fid, '%s%s', 'Delimiter', '\t');
    % fclose(fid);

    % note that filtered aucs could be empty, for all terms are fully annotated
    % like root, which results in NaN AUC.
    aucs = cafa_sel_valid_term_auc(aucs); % keep only participating models
    if ~isempty(aucs)
      cafa_plot_term_avgauc(saveto, ont_str, aucs, config.oa.ontology, yaxis_auc);
    else
      warning('No model is selected.');
    end
  end
  % }}}

  % [FOR TEST] averaged AUC (over top 5 teams) {{{
  if config.do_term_auc && strcmp(scheme, 'test')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top5avg_auc_bar', plot_ext);
    fmaxs  = cafa_collect(config.eval_dir, 'seq_fmax_bst');
    [~, ~, info] = cafa_sel_top_seq_fmax(5, fmaxs, naive, blast, reg, isdump);
    aucs = cafa_collect(config.eval_dir, 'term_auc');

    % % load term acc <--> term name table
    % fid = fopen(config.ont_term, 'r');
    % terms = textscan(fid, '%s%s', 'Delimiter', '\t');
    % fclose(fid);

    % select top 5 methods
    aucs = cafa_get_term_auc(aucs, info.top_mid);

    % note that filtered aucs could be empty, for all terms are fully annotated
    % like root, which results in NaN AUC.
    aucs = cafa_sel_valid_term_auc(aucs); % keep only participating models
    if ~isempty(aucs)
      cafa_plot_term_avgauc(saveto, ont_str, aucs, config.oa.ontology, yaxis_auc);
    else
      warning('No model is selected.');
    end
  end
  % }}}

  % all AUC sheet {{{
  if config.do_term_auc && strcmp(scheme, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_auc_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_auc_sheet_disclosed', sheet_ext);
    aucs = cafa_collect(config.eval_dir, 'term_auc');
    if strcmp(config.ont, 'hpo')
      cafa_sheet_term_auc(saveto_A, aucs, reg, isdump, true);
      cafa_sheet_term_auc(saveto_N, aucs, reg, isdump, false);
    else % MFO, BPO, CCO
      cafa_sheet_term_auc(saveto_A, aucs, reg, isdump, true);
      cafa_sheet_term_auc(saveto_N, aucs, reg, isdump, false);
    end
  end
  % }}}

  % top10 methods in averaged AUC (over all terms) bar {{{
  if config.do_term_auc && ((strcmp(scheme, 'paper') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) || strcmp(scheme, 'all'))
    if strcmp(scheme, 'paper')
      yaxis_auc = [0.2, 1.0, 0.1];
    end
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_auc_bar', plot_ext);
    aucs = cafa_collect(config.eval_dir, 'term_auc');
    [top10, baseline, info] = cafa_sel_top_term_auc(10, aucs, naive, blast, reg, isdump);
    if isempty(top10)
      warning('cafa_driver_result:FewTerm', 'All terms are positive, No plots are generated.');
    else
      cafa_barplot_term_auc(saveto, ont_str, top10, baseline, yaxis_auc);
    end
  end
  % }}}
return

% function: save_team_info {{{
function [] = save_team_info(saveto, info, reg)
  [iid, eid, tname, ~, dname, ~, pi] = cafa_team_register(reg);
  fid = fopen(saveto, 'w');
  fprintf(fid, 'qualified model counts [%3d]\n', numel(info.all_mid));
  fprintf(fid, '----------------------------\n');
  fprintf(fid, 'internal,external,teamname,display,pi\n');
  for i = 1 : numel(info.all_mid)
    [~, j] = ismember(info.all_mid{i}, iid);
    fprintf(fid, '%s,%s,%s,%s,%s\n', iid{j}, eid{j}, tname{j}, dname{j}, pi{j});
  end
  fprintf(fid, '\n');
  fprintf(fid, 'top 10 models (at most one per PI)\n');
  fprintf(fid, '----------------------------------\n');
  fprintf(fid, 'internal,external,teamname,display,pi\n');
  for i = 1 : numel(info.top_mid)
    [~, j] = ismember(info.top_mid{i}, iid);
    fprintf(fid, '%s,%s,%s,%s,%s\n', iid{j}, eid{j}, tname{j}, dname{j}, pi{j});
  end
  fclose(fid);
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Sat 15 Jul 2017 12:19:52 AM E
