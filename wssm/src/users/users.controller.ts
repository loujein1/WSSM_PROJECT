import {
    Controller,
    Post,
    Body,
    UsePipes,
    ValidationPipe,
    Get,
    Param,
    HttpException,
    Patch,
    Delete,
    HttpStatus,
    NotFoundException,
    UnauthorizedException,
    Inject,
  } from '@nestjs/common';
  import { UsersService } from './users.service';
  import { CreateUserDto } from './dto/CreateUser.dto';
  import mongoose from 'mongoose';
  import { UpdateUserDto } from './dto/UpdateUser.dto';

import { Cache } from 'cache-manager';

interface VerificationCodeCache {
  code: string;
  expirationTime: number;  // expirationTime in milliseconds
}

  
  @Controller('users')
  export class UsersController {
    jwtService: any;
    constructor(private usersService: UsersService, ) {
      
    }
  
    @Post('signup')
  @UsePipes(new ValidationPipe()) // ✅ This ensures validation
  createUser(@Body() createUserDto: CreateUserDto) {
    console.log("Signup API hit:", createUserDto);
    return this.usersService.register(createUserDto);
  }

  @Post('login')
async login(@Body() body: { email: string, password: string }) {
  return this.usersService.login(body.email, body.password);
}


  
    @Get()
    getUsers() {
      return this.usersService.getsUsers();
    }
  
    // users/:id
    @Get(':id')
    async getUserById(@Param('id') id: string) {
      const isValid = mongoose.Types.ObjectId.isValid(id);
      if (!isValid) throw new HttpException('User not found', 404);
      const findUser = await this.usersService.getUserById(id);
      if (!findUser) throw new HttpException('User not found', 404);
      return findUser;
    }
  
    @Patch(':id') // PATCH /users/:id
  async updateUser(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    try {
      const updatedUser = await this.usersService.updateUser(id, updateUserDto);
      if (!updatedUser) {
        throw new HttpException('User not found', HttpStatus.NOT_FOUND);
      }
      return updatedUser; // Return updated user
    } catch (error) {
      throw new HttpException(error.message, HttpStatus.BAD_REQUEST);
    }
  }
  
    @Delete(':id')
    async deleteUser(@Param('id') id: string) {
      const isValid = mongoose.Types.ObjectId.isValid(id);
      if (!isValid) throw new HttpException('Invalid ID', 400);
      const deletedUser = await this.usersService.deleteUser(id);
      if (!deletedUser) throw new HttpException('User Not Found', 404);
      return;
    }

    

    
  }