import AWS from 'aws-sdk';
import dotenv from 'dotenv';
import { EncryptionService } from '../utils';

dotenv.config();

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1',
});

const BUCKET_NAME = process.env.AWS_S3_BUCKET || 'concierge-medicine-bucket';

export class StorageService {
  static async uploadFile(
    fileKey: string,
    fileContent: Buffer,
    contentType: string,
    encrypt: boolean = true,
  ): Promise<string> {
    try {
      let content = fileContent;

      // Encrypt file content if requested
      if (encrypt) {
        const encryptedContent = EncryptionService.encrypt(fileContent.toString('base64'));
        content = Buffer.from(encryptedContent);
      }

      const params = {
        Bucket: BUCKET_NAME,
        Key: fileKey,
        Body: content,
        ContentType: contentType,
        ServerSideEncryption: 'AES256',
      };

      const result = await s3.upload(params).promise();
      return result.Location;
    } catch (error) {
      console.error('File upload error:', error);
      throw new Error('Failed to upload file');
    }
  }

  static async downloadFile(fileKey: string, decrypt: boolean = true): Promise<Buffer> {
    try {
      const params = {
        Bucket: BUCKET_NAME,
        Key: fileKey,
      };

      const result = await s3.getObject(params).promise();
      let content = result.Body as Buffer;

      // Decrypt file content if requested
      if (decrypt) {
        const decryptedContent = EncryptionService.decrypt(content.toString());
        content = Buffer.from(decryptedContent, 'base64');
      }

      return content;
    } catch (error) {
      console.error('File download error:', error);
      throw new Error('Failed to download file');
    }
  }

  static async deleteFile(fileKey: string): Promise<void> {
    try {
      const params = {
        Bucket: BUCKET_NAME,
        Key: fileKey,
      };

      await s3.deleteObject(params).promise();
    } catch (error) {
      console.error('File deletion error:', error);
      throw new Error('Failed to delete file');
    }
  }

  static async generatePresignedUrl(fileKey: string, expirationSeconds: number = 3600): Promise<string> {
    try {
      const params = {
        Bucket: BUCKET_NAME,
        Key: fileKey,
        Expires: expirationSeconds,
      };

      const url = s3.getSignedUrl('getObject', params);
      return url;
    } catch (error) {
      console.error('Presigned URL generation error:', error);
      throw new Error('Failed to generate presigned URL');
    }
  }

  static generateFileKey(userId: string, fileType: string, fileName: string): string {
    const timestamp = Date.now();
    return `medical-records/${userId}/${fileType}/${timestamp}_${fileName}`;
  }

  static async listFiles(prefix: string): Promise<string[]> {
    try {
      const params = {
        Bucket: BUCKET_NAME,
        Prefix: prefix,
      };

      const result = await s3.listObjectsV2(params).promise();
      return (result.Contents || []).map((obj) => obj.Key || '');
    } catch (error) {
      console.error('File listing error:', error);
      throw new Error('Failed to list files');
    }
  }
}
