#!/bin/sh

export TPM2TOOLS_TCTI="device:/dev/tpmrm0"
alg_primary_obj=sha256
alg_primary_key=ecc
alg_create_obj=sha256
alg_create_key=keyedhash
#alg_pcr_policy=sha1
#pcr_ids="0,1,2,3"
secret="12345678"

#file_pcr_value=pcr.bin
file_input_data=secret.data
#file_policy=policy.data
file_primary_key_ctx=context.p_"$alg_primary_obj"_"$alg_primary_key"
file_unseal_key_pub=opu_"$alg_create_obj"_"$alg_create_key"
file_unseal_key_priv=opr_"$alg_create_obj"_"$alg_create_key"
file_unseal_key_ctx=ctx_load_out_"$alg_primary_obj"_"$alg_primary_key"-"$alg_create_obj"_"$alg_create_key"
file_unseal_key_name=name.load_"$alg_primary_obj"_"$alg_primary_key"-"$alg_create_obj"_"$alg_create_key"
file_unseal_output_data=usl_"$file_unseal_key_ctx"


cleanup() {
        echo "cleaning up files" &> /dev/console
  rm -f $file_input_data $file_primary_key_ctx $file_unseal_key_pub \
        $file_unseal_key_priv $file_unseal_key_ctx $file_unseal_key_name \
        $file_unseal_output_data $file_pcr_value $file_policy
}
create() {
        echo "creating primary key and passphrase in tpm..." &> /dev/console
        echo $secret > $file_input_data
        tpm2_createprimary -Q -H e -g $alg_primary_obj -G $alg_primary_key -C $file_primary_key_ctx
        tpm2_evictcontrol -A o -c $file_primary_key_ctx -S 0x81000000
        tpm2_create -Q -g $alg_create_obj -G $alg_create_key -u $file_unseal_key_pub -r $file_unseal_key_priv -I $file_input_data -c $file_primary_key_ctx
        tpm2_load -Q -c $file_primary_key_ctx  -u $file_unseal_key_pub  -r $file_unseal_key_priv -n $file_unseal_key_name -C $file_unseal_key_ctx
        tpm2_evictcontrol -A o -c $file_unseal_key_ctx -S 0x81020000
}

pwdgen() {
        echo "adding new password to luks slot and removing the default..." &> /dev/console
        mkdir -p /key-dir/
        mount /dev/sda1 /key-dir/
        sleep 1
        cryptsetup luksAddKey /dev/sda3 $file_input_data --key-file=/key-dir/secret.key
        cryptsetup luksRemoveKey /dev/sda3 --key-file=/key-dir/secret.key
        rm -rf /key-dir/secret.key
        umount /dev/sda1
        sleep 1
        rmdir /key-dir
}

unseal() {
        tpm2_unseal -Q -H 0x81020000 -o $file_input_data
}

#check tpm presence
test -e /dev/tpm0
TPM_PRESENCE=$?
if [ $TPM_PRESENCE == 0 ];
then
        echo "tpm found, checking tpm persistence..." &> /dev/console
        #check tpm persistence
        tpm2_listpersistent|grep persistent &>/dev/null
        TPM2_PERS_STATUS=$?

        if [ $TPM2_PERS_STATUS == 0 ];
        then
                TPM2_PERS_STATUS=0
                echo "not empty tpm persistent, skipping key generation..." &> /dev/console
        else
                TPM2_PERS_STATUS=1
                echo "empty tpm persistent" >& /dev/console
                create
                unseal
                pwdgen
                cleanup
        fi
fi
