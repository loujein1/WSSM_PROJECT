import {
  Controller,
  Post,
  Body,
  UsePipes,
  ValidationPipe,
  Get,
  Param,
  HttpException,
  HttpStatus,
  Patch,
  Delete,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/CreateUser.dto';
import { UpdateUserDto } from './dto/UpdateUser.dto';
import { ForgotPasswordDto, ResetPasswordDto } from './dto/ForgotPassword.dto';
import mongoose from 'mongoose';

@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  // ✅ User Registration with Structured Response
  @Post('signup')
  @UsePipes(new ValidationPipe())
  async createUser(@Body() createUserDto: CreateUserDto) {
    console.log("🔹 Signup API hit with:", createUserDto);
    
    const newUser = await this.usersService.register(createUserDto);

    // ✅ Ensure response is an object, not an array
    if (Array.isArray(newUser)) {
      throw new HttpException({ message: "Unexpected response type from service" }, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    return {
      success: true,
      message: "User registered successfully!",
      user: newUser,
    };
  }

  // ✅ User Login with JWT Token Response
  @Post('login')
  async login(@Body() body: { email: string; password: string }) {
    console.log("🔹 Login API hit for email:", body.email);
    
    const loginResponse = await this.usersService.login(body.email, body.password);

    // ✅ Ensure valid response structure
    if (!loginResponse || typeof loginResponse !== "object") {
      throw new HttpException({ message: "Unexpected response type from service" }, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    return {
      success: true,
      message: "Login successful!",
      token: loginResponse.token,
      user: loginResponse.user,
    };
  }

  // ✅ Fetch All Users
  @Get()
  async getUsers() {
    try {
      const users = await this.usersService.getUsers();
      return {
        success: true,
        message: "Users retrieved successfully",
        users,
      };
    } catch (error) {
      throw new HttpException(
        { message: error.message || "Failed to fetch users" },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // ✅ Get a Single User by ID
  @Get(':id')
  async getUserById(@Param('id') id: string) {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new HttpException({ message: "Invalid User ID" }, HttpStatus.BAD_REQUEST);
    }

    const user = await this.usersService.getUserById(id);
    if (!user) {
      throw new HttpException({ message: "User not found" }, HttpStatus.NOT_FOUND);
    }

    return {
      success: true,
      message: "User retrieved successfully",
      user,
    };
  }

  // ✅ Update User Information
  @Patch(':id')
  @UsePipes(new ValidationPipe())
  async updateUser(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new HttpException({ message: "Invalid User ID" }, HttpStatus.BAD_REQUEST);
    }

    const updatedUser = await this.usersService.updateUser(id, updateUserDto);
    if (!updatedUser) {
      throw new HttpException({ message: "User not found or update failed" }, HttpStatus.NOT_FOUND);
    }

    return {
      success: true,
      message: "User updated successfully",
      user: updatedUser,
    };
  }

  // ✅ Delete a User
  @Delete(':id')
  async deleteUser(@Param('id') id: string) {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new HttpException({ message: "Invalid User ID" }, HttpStatus.BAD_REQUEST);
    }

    const deletedUser = await this.usersService.deleteUser(id);
    if (!deletedUser) {
      throw new HttpException({ message: "User not found or deletion failed" }, HttpStatus.NOT_FOUND);
    }

    return {
      success: true,
      message: "User deleted successfully",
    };
  }

  // ✅ Forgot Password Endpoint
  @Post('forgot-password')
  @UsePipes(new ValidationPipe())
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    console.log("🔹 Forgot Password API hit for email:", forgotPasswordDto.email);
    
    const result = await this.usersService.forgotPassword(forgotPasswordDto.email);
    
    return result;
  }

  // ✅ Reset Password Endpoint
  @Post('reset-password')
  @UsePipes(new ValidationPipe())
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    console.log("🔹 Reset Password API hit");
    
    const result = await this.usersService.resetPassword(
      resetPasswordDto.token,
      resetPasswordDto.password
    );
    
    return result;
  }
}
