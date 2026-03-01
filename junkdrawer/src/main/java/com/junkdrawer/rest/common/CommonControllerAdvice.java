/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.common;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.validation.method.ParameterErrors;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.common.PermissionException;

@ControllerAdvice
public class CommonControllerAdvice {

    private static final String INSTANCE_NOT_FOUND_EXCEPTION_CODE = "project.exceptions.InstanceNotFoundException";
    private static final String DUPLICATE_INSTANCE_EXCEPTION_CODE = "project.exceptions.DuplicateInstanceException";
    private static final String PERMISSION_EXCEPTION_CODE = "project.exceptions.PermissionException";

    private final MessageSource messageSource;

    public CommonControllerAdvice(MessageSource messageSource) {
        this.messageSource = messageSource;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ResponseBody
    public ErrorsDto handleMethodArgumentNotValidException(MethodArgumentNotValidException exception) {
        List<FieldErrorDto> fieldErrors = exception.getBindingResult().getFieldErrors().stream()
                .map(error -> new FieldErrorDto(error.getField(), error.getDefaultMessage()))
                .toList();

        return new ErrorsDto(fieldErrors);
    }

    @ExceptionHandler(InstanceNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    @ResponseBody
    public ErrorsDto handleInstanceNotFoundException(InstanceNotFoundException exception, Locale locale) {
        String nameMessage = messageSource.getMessage(exception.getName(), null, exception.getName(), locale);
        String errorMessage = messageSource.getMessage(
                INSTANCE_NOT_FOUND_EXCEPTION_CODE,
                new Object[] { nameMessage, exception.getKey().toString() },
                INSTANCE_NOT_FOUND_EXCEPTION_CODE,
                locale);

        return new ErrorsDto(errorMessage);
    }

    @ExceptionHandler(DuplicateInstanceException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ResponseBody
    public ErrorsDto handleDuplicateInstanceException(DuplicateInstanceException exception, Locale locale) {
        String nameMessage = messageSource.getMessage(exception.getName(), null, exception.getName(), locale);
        String errorMessage = messageSource.getMessage(
                DUPLICATE_INSTANCE_EXCEPTION_CODE,
                new Object[] { nameMessage, exception.getKey().toString() },
                DUPLICATE_INSTANCE_EXCEPTION_CODE,
                locale);

        return new ErrorsDto(errorMessage);
    }

    @ExceptionHandler(HandlerMethodValidationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ResponseBody
    public ErrorsDto handleParams(HandlerMethodValidationException exception) {
        var fieldErrors = new ArrayList<FieldErrorDto>();

        exception.getParameterValidationResults().forEach(result -> {
            var parameter = result.getMethodParameter();
            String parameterName = parameter.getParameterName() != null
                    ? parameter.getParameterName()
                    : "arg" + parameter.getParameterIndex();

            if (result instanceof ParameterErrors errors) {
                errors.getFieldErrors().forEach(error ->
                        fieldErrors.add(new FieldErrorDto(error.getField(), error.getDefaultMessage())));
            } else {
                result.getResolvableErrors().forEach(error ->
                        fieldErrors.add(new FieldErrorDto(parameterName, error.getDefaultMessage())));
            }
        });

        return new ErrorsDto(fieldErrors);
    }

    @ExceptionHandler(PermissionException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    @ResponseBody
    public ErrorsDto handlePermissionException(Locale locale) {
        String errorMessage = messageSource.getMessage(
                PERMISSION_EXCEPTION_CODE,
                null,
                PERMISSION_EXCEPTION_CODE,
                locale);

        return new ErrorsDto(errorMessage);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ResponseBody
    public ErrorsDto handleIllegalArgumentException(IllegalArgumentException exception) {
        return new ErrorsDto(exception.getMessage());
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    @ResponseStatus(HttpStatus.PAYLOAD_TOO_LARGE)
    @ResponseBody
    public ErrorsDto handleMaxUploadSizeExceededException(MaxUploadSizeExceededException exception) {
        return new ErrorsDto("El archivo supera el tamaño máximo permitido.");
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    @ResponseBody
    public ErrorsDto handleDataIntegrityViolationException(DataIntegrityViolationException exception) {
        return new ErrorsDto("El archivo ya existe o hay un conflicto con los datos enviados.");
    }
}
