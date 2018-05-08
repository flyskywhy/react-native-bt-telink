//
//  CryptoUtil.h
//  TelinkBlue
//
//  Created by Green on 11/15/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#ifndef __TelinkBlue__CryptoUtil__
#define __TelinkBlue__CryptoUtil__

#include <stdio.h>


void _rijndaelSetKey (unsigned char *k);
void _rijndaelEncrypt(unsigned char *a);
void _rijndaelDecrypt (unsigned char *a);

void aes_att_encryption (unsigned char *key, unsigned char *plaintext, unsigned char *result);
void aes_att_decryption (unsigned char *key, unsigned char *plaintext, unsigned char *result);


int		aes_att_er (unsigned char *pNetworkName, unsigned char *pPassword, unsigned char *prand, unsigned char *presult);
#endif /* defined(__TelinkBlue__CryptoUtil__) */
