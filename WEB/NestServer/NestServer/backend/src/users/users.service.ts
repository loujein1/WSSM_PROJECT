import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from 'src/water-usage/schemas/User.schema';
import { CreateUserDto } from './dto/CreateUser.dto';
import { UpdateUserDto } from './dto/UpdateUser.dto';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'crypto';
import { MailerService } from '@nestjs-modules/mailer';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    private readonly jwtService: JwtService,
    private readonly mailerService: MailerService
  ) {}

  async register(createUserDto: CreateUserDto) {
    console.log("🔹 Signup Attempt:", createUserDto.email);
  
    const existingUser = await this.userModel.findOne({ email: createUserDto.email });
    if (existingUser) {
      throw new HttpException({ message: 'Email already in use' }, HttpStatus.CONFLICT);
    }
  
    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);
  
    const newUser = new this.userModel({
      email: createUserDto.email,
      username: createUserDto.username,
      password: hashedPassword,
      role: createUserDto.role || "user", // Default to "user" if not specified
    });
  
    const savedUser = await newUser.save();
  
    console.log("✅ User Registered:", savedUser.email);
  
    return {
      success: true,
      message: "User registered successfully!",
      user: {
        id: savedUser._id,
        email: savedUser.email,
        username: savedUser.username,
        role: savedUser.role,
      },
    };
  }
  
  async login(email: string, password: string) {
    console.log("🔹 Login Attempt for:", email);

    const user = await this.userModel.findOne({ email }).select("+password");

    if (!user) {
      console.log("❌ No user found!");
      throw new HttpException({ message: 'Invalid email or password' }, HttpStatus.UNAUTHORIZED);
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      console.log("❌ Password does not match!");
      throw new HttpException({ message: 'Invalid email or password' }, HttpStatus.UNAUTHORIZED);
    }

    // Generate JWT Token with user info
    const payload = { 
      email: user.email, 
      sub: user._id, 
      role: user.role,
      username: user.username 
    };
    const token = this.jwtService.sign(payload);

    console.log("✅ Login successful for:", email);

    return {
      success: true,
      message: "Login successful!",
      token,
      user: {
        id: user._id,
        email: user.email,
        username: user.username,
        role: user.role,
      },
    };
  }

  // ✅ Fetch All Users (Admin Use Only)
  async getUsers() {
    try {
      const users = await this.userModel.find().select("-password");
      return users;
    } catch (error) {
      throw new HttpException(
        { message: "Failed to fetch users" },
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getUserById(id: string) {
    if (!id.match(/^[0-9a-fA-F]{24}$/)) {
      throw new HttpException({ message: "Invalid User ID" }, HttpStatus.BAD_REQUEST);
    }

    try {
      const user = await this.userModel.findById(id).select("-password");
      if (!user) {
        throw new HttpException({ message: "User not found" }, HttpStatus.NOT_FOUND);
      }

      return {
        success: true,
        message: "User retrieved successfully",
        user,
      };
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      console.error("Error fetching user:", error);
      throw new HttpException(
        { message: 'Failed to retrieve user' },
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async updateUser(id: string, updateUserDto: UpdateUserDto) {
    if (!id.match(/^[0-9a-fA-F]{24}$/)) {
      throw new HttpException({ message: "Invalid User ID" }, HttpStatus.BAD_REQUEST);
    }

    try {
      // Create a copy of the DTO to avoid modifying the original
      const updateData = { ...updateUserDto };

      // If password is being updated, hash it
      if (updateData.password) {
        updateData.password = await bcrypt.hash(updateData.password, 10);
      }

      const updatedUser = await this.userModel.findByIdAndUpdate(
        id, 
        updateData, 
        { new: true }
      ).select("-password");
      
      if (!updatedUser) {
        throw new HttpException({ message: "User not found or update failed" }, HttpStatus.NOT_FOUND);
      }

      console.log("✅ User updated successfully:", updatedUser.email);

      return {
        success: true,
        message: "User updated successfully",
        user: updatedUser,
      };
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      console.error("Error updating user:", error);
      throw new HttpException(
        { message: 'Failed to update user' },
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async deleteUser(id: string) {
    if (!id.match(/^[0-9a-fA-F]{24}$/)) {
      throw new HttpException({ message: "Invalid User ID" }, HttpStatus.BAD_REQUEST);
    }

    try {
      const deletedUser = await this.userModel.findByIdAndDelete(id);
      if (!deletedUser) {
        throw new HttpException({ message: "User not found or deletion failed" }, HttpStatus.NOT_FOUND);
      }

      console.log("✅ User deleted successfully:", deletedUser.email);

      return {
        success: true,
        message: "User deleted successfully",
      };
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      console.error("Error deleting user:", error);
      throw new HttpException(
        { message: 'Failed to delete user' },
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async forgotPassword(email: string) {
    console.log("🔹 Forgot Password Request for:", email);
  
    const user = await this.userModel.findOne({ email });
    if (!user) {
      return {
        success: true,
        message: "If your email is registered, you will receive a password reset link",
      };
    }
  
    const resetToken = crypto.randomBytes(32).toString('hex');
    const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex');
  
    user.resetToken = hashedToken;
    user.resetTokenExpiry = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();
  
    // Update the reset URL to point to your Flutter web app
    const resetUrl = `http://localhost:8080/#/reset-password/${resetToken}`;
  
    try {
      await this.mailerService.sendMail({
        to: user.email,
        subject: 'Password Reset Request',
        html: `
          <h3>Password Reset Request</h3>
          <p>You requested to reset your password. Click the link below to reset it:</p>
          <p><a href="${resetUrl}">Reset Password</a></p>
          <p>This link will expire in 10 minutes.</p>
          <p>If you didn't request this, please ignore this email.</p>
        `,
      });
  
      return {
        success: true,
        message: "If your email is registered, you will receive a password reset link",
      };
    } catch (error) {
      user.resetToken = null;
      user.resetTokenExpiry = null;
      await user.save();
  
      console.error('Email send error:', error);
      throw new HttpException(
        { message: 'Error sending reset email' },
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async resetPassword(token: string, newPassword: string) {
    console.log("🔹 Reset Password Request with token");

    try {
      // Hash the token to compare with the one in the database
      const hashedToken = crypto
        .createHash('sha256')
        .update(token)
        .digest('hex');

      // Find user with the token and check if token is still valid
      const user = await this.userModel.findOne({
        resetToken: hashedToken,
        resetTokenExpiry: { $gt: new Date() },
      });

      if (!user) {
        console.log("❌ Invalid or expired token for password reset");
        throw new HttpException(
          { message: 'Invalid or expired token' },
          HttpStatus.BAD_REQUEST
        );
      }

      // Update password and clear reset token fields
      user.password = await bcrypt.hash(newPassword, 10);
      user.resetToken = null;
      user.resetTokenExpiry = null;
      await user.save();

      console.log("✅ Password reset successful for user:", user.email);

      return {
        success: true,
        message: "Password has been reset successfully",
      };
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      console.error("Error in reset password process:", error);
      throw new HttpException(
        { message: 'Error processing password reset' },
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // Update user role (admin only)
  async updateUserRole(userId: string, newRole: string) {
    if (!userId.match(/^[0-9a-fA-F]{24}$/)) {
      throw new HttpException({ message: "Invalid User ID" }, HttpStatus.BAD_REQUEST);
    }

    if (!['user', 'admin'].includes(newRole)) {
      throw new HttpException({ message: "Invalid role. Must be 'user' or 'admin'" }, HttpStatus.BAD_REQUEST);
    }

    try {
      const updatedUser = await this.userModel.findByIdAndUpdate(
        userId,
        { role: newRole },
        { new: true }
      ).select("-password");

      if (!updatedUser) {
        throw new HttpException({ message: "User not found or update failed" }, HttpStatus.NOT_FOUND);
      }

      console.log(`✅ User role updated to ${newRole} for:`, updatedUser.email);

      return {
        success: true,
        message: `User role updated to ${newRole} successfully`,
        user: updatedUser,
      };
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      console.error("Error updating user role:", error);
      throw new HttpException(
        { message: 'Failed to update user role' },
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
}
