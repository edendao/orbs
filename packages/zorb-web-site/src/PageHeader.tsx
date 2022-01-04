import { css } from "@emotion/css";
import React from "react";
import Octo from "./octo";

export const PageHeader = ({ children }: { children: React.ReactNode }) => (
  <div
    className={css`
      font-family: "DM Mono";

      display: flex;
      flex-direction: column;
    `}
  >
    <div
      className={css`
        padding: 0px 10px;
        display: flex;

        display: flex;
        justify-content: space-between;
        align-items: center;

        margin-bottom: 20px;
      `}
    >
      <a
      href="/"
        className={css`
          color: #f6f6f6;

          text-decoration: none;

          font-family: DM Mono;
          font-style: normal;
          font-weight: normal;
          font-size: 16px;
          line-height: 21px;

          /* identical to box height */
          letter-spacing: -0.02em;

          opacity: 0.5;
        `}
      >
        <span
            className={css`
              opacity: 0.5;
            `}
          >
            npm i{" "}
          </span>
          <span>@zoralabs/zorb</span>
        {/*on-chain <span>zorb</span>*/}
      </a>
      <a target="_BLANK" href="https://github.com/ourzora/zorb">
        <Octo />
      </a>
    </div>
    <div
      className={css`
        flex-grow: 1;
      `}
    >
      {children}
    </div>
  </div>
);
