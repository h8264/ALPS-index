
# warp FA to MNI space with FSL tbss pipeline
for s in /home1/xxx/data/BL_network/*
do
    echo ${s##*/} >> to_process.txt  
done

mapfile -t toProcess < "/home1/xxx/script/to_process.txt"
for subj in ${toProcess[*]}
do
s=/home1/xxx/data/BL_network/$subj
cd ${s}
tbss_1_preproc *_FA.nii.gz
tbss_2_reg -T
done

# apply the FA-to-MNI matrix to FA image
norm_FA() {
    s=$1
    subj=${s}
    applywarp --ref=${FSLDIR}/data/standard/FMRIB58_FA_1mm --in=/home1/xxx/data/BL_network/${subj}/origdata/dtifit_${subj}_FA.nii.gz --warp=/home1/xxx/data/BL_network/${subj}/FA/dtifit_${subj}_FA_FA_to_target_warp.nii.gz --out=/home1/xxx/data/FAwarped/dtifit_${subj}_FA_FA_to_target.nii.gz
}
mapfile -t toProcess < "/home1/xxx/script/to_process.txt"
export -f norm_FA
parallel -j 20 norm_FA {} ::: "${toProcess[@]}"

# warp V1 and MD to MNI space with the transformation matrix from FA to MNI
norm_others() {
    s=$1
    subj=${s}
    applywarp --ref=${FSLDIR}/data/standard/FMRIB58_FA_1mm --in=/home1/xxx/data/BL_network/${subj}/dtifit_${subj}_V1.nii.gz --warp=/home1/xxx/data/BL_network/${subj}/FA/dtifit_${subj}_FA_FA_to_target_warp.nii.gz --out=/home1/xxx/data/FAwarped/dtifit_${subj}_V1_V1_to_target.nii.gz
    applywarp --ref=${FSLDIR}/data/standard/FMRIB58_FA_1mm --in=/home1/xxx/data/BL_network/${subj}/dtifit_${subj}_MD.nii.gz --warp=/home1/xxx/data/BL_network/${subj}/FA/dtifit_${subj}_FA_FA_to_target_warp.nii.gz --out=/home1/xxx/data/FAwarped/dtifit_${subj}_MD_MD_to_target.nii.gz
}
mapfile -t toProcess < "/home1/xxx/script/to_process.txt"
export -f norm_others
parallel -j 10 norm_others {} ::: "${toProcess[@]}"

# extract dxyz metric
extract_dxyz() {
    s=$1
    subj=${s}
    fslroi /home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor.nii.gz  /home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor_Dxx.nii.gz 0 1
    fslroi /home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor.nii.gz  /home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor_Dyy.nii.gz 3 1
    fslroi /home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor.nii.gz  /home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor_Dzz.nii.gz 5 1
}
mapfile -t toProcess < "/home1/xxx/script/to_process.txt"
export -f extract_dxyz
parallel -j 20 extract_dxyz {} ::: "${toProcess[@]}"

# warp dxyz to MNI space with the transformation matrix from FA to MNI
norm_others() {
    s=$1
    subj=${s}
    applywarp --ref=${FSLDIR}/data/standard/FMRIB58_FA_1mm --in=/home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor_Dxx.nii.gz --warp=/home1/xxx/data/BL_network/${subj}/FA/dtifit_${subj}_FA_FA_to_target_warp.nii.gz --out=/home1/xxx/data/FAwarped/dtifit_${subj}_Dxx_Dxx_to_target.nii.gz
    applywarp --ref=${FSLDIR}/data/standard/FMRIB58_FA_1mm --in=/home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor_Dyy.nii.gz --warp=/home1/xxx/data/BL_network/${subj}/FA/dtifit_${subj}_FA_FA_to_target_warp.nii.gz --out=/home1/xxx/data/FAwarped/dtifit_${subj}_Dyy_Dyy_to_target.nii.gz
    applywarp --ref=${FSLDIR}/data/standard/FMRIB58_FA_1mm --in=/home1/xxx/data/BL_network/${subj}/dtifit_${subj}_tensor_Dzz.nii.gz --warp=/home1/xxx/data/BL_network/${subj}/FA/dtifit_${subj}_FA_FA_to_target_warp.nii.gz --out=/home1/xxx/data/FAwarped/dtifit_${subj}_Dzz_Dzz_to_target.nii.gz
}
mapfile -t toProcess < "/public/home/xxx/script/to_process.txt"
export -f norm_others
parallel -j 10 norm_others {} ::: "${toProcess[@]}"

# convert voi to nifti with code
voi2nifti()

# generate probability mask for ROIs
fslmerge -t combined_masks_L_proj.nii.gz /public/home/xxx/mask/select_roi_manual/dtifit_*_L_proj.nii
fslmaths combined_masks_L_proj.nii.gz -Tmean probability_mask_L_proj.nii
fslmerge -t combined_masks_R_proj.nii.gz /public/home/xxx/mask/select_roi_manual/dtifit_*_R_proj.nii
fslmaths combined_masks_R_proj.nii.gz -Tmean probability_mask_R_proj.nii
fslmerge -t combined_masks_L_asso.nii.gz /public/home/xxx/mask/select_roi_manual/dtifit_*_L_asso.nii
fslmaths combined_masks_L_asso.nii.gz -Tmean probability_mask_L_asso.nii
fslmerge -t combined_masks_R_asso.nii.gz /public/home/xxx/mask/select_roi_manual/dtifit_*_R_asso.nii
fslmaths combined_masks_R_asso.nii.gz -Tmean probability_mask_R_asso.nii

# get thresholded binary mask
thrs=(0.2 0.4 0.6 0.8)
for s in probability_mask*
do
    prefix=${s/.nii.gz/}
    stats=`fslstats ${s} -R`
    max_value=$(echo $stats | awk '{print $2}')
    for t in "${thrs[@]}"
    do
        threshold=$(echo "scale=6; ${t} * ${max_value}" | bc)
        fslmaths $s -thr $threshold ${prefix}_${t}.nii.gz
    done
done

# generate values required by ALPS index
while read i; 
do 
    subj=${i}
    a=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dxx_Dxx_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_L_proj_0.6.nii.gz -M`
    b=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dxx_Dxx_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_R_proj_0.6.nii.gz -M`
    c=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dxx_Dxx_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_L_asso_0.6.nii.gz -M`
    d=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dxx_Dxx_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_R_asso_0.6.nii.gz -M`
    echo ${a},${b},${c},${d} >> /public/home/xxx/data/Dxx1.txt
done < /public/home/xxx/data/used_subjs1.txt

while read i; 
do 
    subj=${i}
    a=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dyy_Dyy_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_L_proj_0.6.nii.gz -M`
    b=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dyy_Dyy_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_R_proj_0.6.nii.gz -M`
    c=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dyy_Dyy_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_L_asso_0.6.nii.gz -M`
    d=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dyy_Dyy_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_R_asso_0.6.nii.gz -M`
    echo ${a},${b},${c},${d} >> /public/home/xxx/data/Dyy1.txt
done < /public/home/xxx/data/used_subjs1.txt

while read i; 
do 
    subj=${i}
    a=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dzz_Dzz_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_L_proj_0.6.nii.gz -M`
    b=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dzz_Dzz_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_R_proj_0.6.nii.gz -M`
    c=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dzz_Dzz_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_L_asso_0.6.nii.gz -M`
    d=`fslstats /home1/xxx/data/FAwarped/dtifit_${subj}_Dzz_Dzz_to_target.nii.gz -k /public/home/xxx/mask/probability_mask_R_asso_0.6.nii.gz -M`
    echo ${a},${b},${c},${d} >> /public/home/xxx/data/Dzz1.txt
done < /public/home/xxx/data/used_subjs1.txt

# calculate ALPS index 
ALPS.m

