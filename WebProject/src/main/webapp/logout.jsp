<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.Cookie" %>

<%
    // 사용자 쿠키 제거
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            // userName 쿠키 삭제
            if ("userName".equals(cookie.getName())) {
                cookie.setValue(""); // 빈 값으로 설정
                cookie.setMaxAge(0); // 쿠키 유효시간 0으로 설정
                response.addCookie(cookie); // 응답에 반영
            }
        }
    }

    // 세션 무효화 (만약 세션을 사용했다면)
    if (session != null) {
        session.invalidate();
    }

    // 로그인 페이지로 리다이렉트
    response.sendRedirect("login.jsp");
%>
