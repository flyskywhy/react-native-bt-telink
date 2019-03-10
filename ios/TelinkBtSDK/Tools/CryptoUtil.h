/********************************************************************************************************
 * @file     CryptoUtil.h 
 *
 * @brief    for TLSR chips
 *
 * @author	 telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *           
 *			 The information contained herein is confidential and proprietary property of Telink 
 * 		     Semiconductor (Shanghai) Co., Ltd. and is available under the terms 
 *			 of Commercial License Agreement between Telink Semiconductor (Shanghai) 
 *			 Co., Ltd. and the licensee in separate contract or the terms described here-in. 
 *           This heading MUST NOT be removed from this file.
 *
 * 			 Licensees are granted free, non-transferable use of the information in this 
 *			 file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided. 
 *           
 *******************************************************************************************************/
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
